# Pedido de Certificado SSL

## Como rodar os testes

```bash
bundle install      # pré-requisito: Ruby >= 3.x
bundle exec rspec
```

Resultado esperado: todos os exemplos passando, zero failures.

---

## Estrutura do projeto

```
lib/
  order.rb                          # Context (State Pattern) - coordena o ciclo de vida
  order/
    errors.rb                       # Exceções tipadas do domínio (SRP)
    validators/
      domain_validator.rb           # Strategy: valida formato de domínio
      provider_validator.rb         # Strategy: valida whitelist de provedores
    states/
      base.rb                       # Template Method: esqueleto de transição
      final_state.rb                # Estado base para estados finais
      pending.rb                    # State: transições a partir de pending
      validating.rb                 # State: transições + lógica de retry
      issued.rb                     # State: transições a partir de issued
      installed.rb                  # State: estado final - bloqueia tudo
      failed.rb                     # State: estado final - bloqueia tudo

spec/
  spec_helper.rb
  order/
    initialization_spec.rb          # criação válida e inválida
    transitions/
      happy_path_spec.rb            # pending → validating → issued → installed
      cancel_spec.rb                # cancel de qualquer estado não-final
      invalid_transitions_spec.rb   # eventos recusados sem mudar o estado
      validation_retry_spec.rb      # validate_fail com retry até o limite
      final_states_spec.rb          # installed e failed bloqueiam tudo
    validators/
      domain_validator_spec.rb      # DomainValidator testado isoladamente
      provider_validator_spec.rb    # ProviderValidator testado isoladamente
```

---

## Design Patterns aplicados

### State Pattern (Behavioral)

Cada estado é uma classe em `Order::States::` que encapsula
suas próprias transições válidas. `Order` (o Context) delega
`#apply` para o estado atual, não conhece nenhuma regra de transição.

```
Order (Context)
  └─ current_state → States::Pending | Validating | Issued | Installed | Failed
                          ↓
                     .apply(event, order) → novo_status
```

Benefício: adicionar um novo estado = criar um arquivo novo e uma entrada em `STATES`.
Nenhum estado existente precisa ser tocado (OCP).

### Template Method (Behavioral)

`States::Base#apply` define o algoritmo imutável:
1. Evento `:cancel`? → retorna `:failed` (universal para não-finais)
2. Senão → delega para `#handle` (sobrescrito por cada subclasse)
3. Subclasse não tratou? → `Base#handle` levanta `InvalidTransition`

Os estados finais (`Installed` e `Failed`) herdam de `FinalState`, que sobrescreve `#apply` para rejeitar qualquer evento (inclusive `:cancel`), garantindo que pedidos em estados finais não possam sofrer novas transições.

### Strategy Pattern (Behavioral)

`DomainValidator` e `ProviderValidator` são estratégias de validação
intercambiáveis, respondem ao mesmo contrato (`#validate!`).
`Order` depende do contrato, não das implementações (DIP).
Cada validador tem sua única regra (SRP) e pode ser testado isoladamente.

---

## Princípios SOLID

| Princípio | Como foi aplicado |
|-----------|-------------------|
| **S** - Single Responsibility | `Order` coordena; cada `State` conhece suas transições; cada `Validator` valida uma regra; `errors.rb` centraliza exceções |
| **O** - Open/Closed | Novo estado = novo arquivo em `states/` + entrada em `STATES`. Novo provedor = mudar só `ProviderValidator`. Código existente não muda |
| **L** - Liskov Substitution | Todos os `States` são substituíveis por `Base`, respondem ao mesmo contrato `.apply` e `.final?` |
| **I** - Interface Segregation | Estados expõem `.apply` e `.final?`; Validators expõem `#validate!`, interfaces mínimas |
| **D** - Dependency Inversion | `Order` depende das abstrações (contrato dos States e Validators), não de implementações concretas |

---

## Parte 2 - Cenário & tecnologias

### 1. API REST em Rails

**Onde mora a lógica?** A classe `Order` (ou um ActiveRecord equivalente)
fica no modelo. Os controllers são finos: recebem a requisição, delegam
ao modelo e devolvem o status HTTP correto.

| Verbo | Rota                             | Ação                          | Status sucesso |
|-------|----------------------------------|-------------------------------|----------------|
| POST  | `/api/v1/orders`                 | Cria um pedido                | 201 Created    |
| GET   | `/api/v1/orders/:id`             | Consulta um pedido            | 200 OK         |
| GET   | `/api/v1/orders`                 | Lista pedidos (com filtros)   | 200 OK         |
| POST  | `/api/v1/orders/:id/transitions` | Aplica um evento de transição | 200 OK         |

O endpoint de transição recebe `{ "event": "start_validation" }`.
Transição inválida → `422 Unprocessable Entity`. Não encontrado → `404`.

```ruby
# app/controllers/api/v1/transitions_controller.rb
class Api::V1::TransitionsController < ApplicationController
  def create
    order = Order.find(params[:order_id])
    order.apply(params.require(:event))
    order.save!
    render json: OrderSerializer.new(order), status: :ok
  rescue Order::InvalidTransition => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Pedido nao encontrado" }, status: :not_found
  end
end
```

A lógica de transição permanece 100% no modelo, o controller só traduz HTTP.

### 2. Front-end em Vue

Três componentes principais:

- **`OrderList.vue`** - lista pedidos via `GET /api/v1/orders`.
  Usa polling leve (ou WebSocket/ActionCable) para atualizar pedidos em `validating`.
- **`OrderStatusBadge.vue`** - recebe o status e renderiza cor/ícone do Design System.
- **`OrderActions.vue`** - exibe os eventos disponíveis para o status atual e dispara
  `POST /api/v1/orders/:id/transitions` ao clicar. Atualiza o item via reatividade do Vue.

```vue
<!-- OrderActions.vue -->
<template>
  <div>
    <button
      v-for="event in availableEvents"
      :key="event"
      :disabled="loading"
      @click="applyEvent(event)"
    >
      {{ labelFor(event) }}
    </button>
  </div>
</template>

<script setup>
import { ref, computed } from "vue"
import { applyTransition } from "@/api/orders"

const props   = defineProps({ order: Object })
const emit    = defineEmits(["updated"])
const loading = ref(false)

const EVENTS_BY_STATUS = {
  pending:    ["start_validation", "cancel"],
  validating: ["cancel"],
  issued:     ["install", "cancel"],
  installed:  [],
  failed:     []
}

const LABELS = {
  start_validation: "Iniciar validação",
  install:          "Instalar",
  cancel:           "Cancelar"
}

const availableEvents = computed(() => EVENTS_BY_STATUS[props.order.status] ?? [])

async function applyEvent(event) {
  loading.value = true
  try {
    const updated = await applyTransition(props.order.id, event)
    emit("updated", updated)
  } finally {
    loading.value = false
  }
}

const labelFor = (event) => LABELS[event] ?? event
</script>
```

### 3. Confiabilidade - validação externa lenta

Uma chamada ao provedor SSL pode demorar minutos. Bloquear a thread do
Rails é inaceitável. Solução: job assíncrono com Sidekiq.

Para `:start_validation` especificamente, o controller enfileira o job e
retorna `202 Accepted` imediatamente, sem chamar `apply` ainda. O job
executa a chamada externa e aplica `:validate_ok` ou `:validate_fail`
ao terminar.

```ruby
# app/controllers/api/v1/transitions_controller.rb (start_validation)
def create
  order = Order.find(params[:order_id])
  ValidateSslOrderJob.perform_later(order.id)
  render json: OrderSerializer.new(order), status: :accepted
rescue ActiveRecord::RecordNotFound
  render json: { error: "Pedido nao encontrado" }, status: :not_found
end
```

```ruby
# app/jobs/validate_ssl_order_job.rb
class ValidateSslOrderJob < ApplicationJob
  queue_as :ssl_validation

  def perform(order_id)
    order  = Order.find(order_id)
    result = SslProviderClient.new(order.provider).validate(order.domain)

    event = result.success? ? :validate_ok : :validate_fail
    order.apply(event)
    order.save!
  rescue Order::InvalidTransition
    # Pedido cancelado enquanto o job aguardava, ignorar silenciosamente.
    Rails.logger.warn("ValidateSslOrderJob: transicao invalida para order #{order_id}")
  end
end
```

**Pontos adicionais que consideraria:**

- **Retry automático do Sidekiq** com back-off exponencial para falhas de rede
  (distintas de `validate_fail` intencional do provedor).
- **Dead letter queue + alerta** (Sentry/Datadog) quando o job falha além do limite.
- **Push no front-end** via ActionCable: o Vue escuta um canal por pedido e atualiza
  a UI sem polling quando o job conclui.
- **Idempotência**: o `rescue Order::InvalidTransition` já cobre casos onde o pedido
  foi cancelado enquanto o job estava na fila.
- **Circuit breaker**: se o provedor estiver fora, parar de enfileirar jobs e retornar
  erro claro imediatamente.

---

## O que faria com mais tempo

1. **Persistência real** - ActiveRecord com `aasm` ou `state_machines-activerecord`
   (geração automática de scopes, callbacks e integração com formulários).
2. **Use Cases + Repository pattern** - a camada de domínio já está isolada do framework;
   o próximo passo seria separar a orquestração em Use Cases e abstrair a persistência
   com um Repository, permitindo testar toda a lógica sem subir Rails ou banco.
3. **Autenticação/autorização** - cada cliente vê/transita apenas seus pedidos (Pundit).
4. **Paginação e filtros** - `GET /orders?status=validating&provider=lets_encrypt&page=2`.
5. **Request specs Rails** - cobrindo os endpoints completos com banco em memória (SQLite em test).
6. **Testes do componente Vue** - Vitest + Vue Test Utils, mockando a API.
7. **Observabilidade** - log estruturado (JSON) de cada transição com `order_id`, `from`,
   `to`, `event` e timestamp; facilita rastrear pedidos presos em `validating`.
8. **Timeout no `SslProviderClient`** - garantir que a chamada ao provedor não bloqueie
   indefinidamente; pré-requisito natural para o circuit breaker.
9. **Circuit breaker** - parar de enfileirar quando o provedor está fora.
10. **Webhooks** - notificar o cliente quando o certificado for emitido ou falhar,
    em vez de depender de polling.
