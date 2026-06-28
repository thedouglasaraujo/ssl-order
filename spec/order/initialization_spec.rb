RSpec.describe Order, "#initialize" do
  context "com dados válidos" do
    subject(:order) { described_class.new(domain: "loja.exemplo.com.br", provider: "lets_encrypt") }

    it "cria o pedido em pending" do
      expect(order.status).to eq(:pending)
    end

    it "começa com zero tentativas de validação" do
      expect(order.validation_attempts).to eq(0)
    end

    it "armazena o domain" do
      expect(order.domain).to eq("loja.exemplo.com.br")
    end

    it "armazena o provider" do
      expect(order.provider).to eq("lets_encrypt")
    end

    it "aceita o provedor globalsign" do
      order = described_class.new(domain: "site.com.br", provider: "globalsign")
      expect(order.provider).to eq("globalsign")
    end

    it "aceita domínio com múltiplos subdomínios" do
      order = described_class.new(domain: "mail.srv.exemplo.com.br", provider: "lets_encrypt")
      expect(order.domain).to eq("mail.srv.exemplo.com.br")
    end
  end

  context "com domínio inválido" do
    it "recusa e levanta InvalidDomain" do
      expect { described_class.new(domain: "invalido", provider: "lets_encrypt") }
        .to raise_error(Order::InvalidDomain)
    end
  end

  context "com provedor inválido" do
    it "recusa e levanta InvalidProvider" do
      expect { described_class.new(domain: "site.com", provider: "digicert") }
        .to raise_error(Order::InvalidProvider)
    end
  end
end