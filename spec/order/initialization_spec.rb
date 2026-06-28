RSpec.describe Order, "#initialize" do
  subject(:order) do
    described_class.new(
      domain: "loja.exemplo.com.br",
      provider: "lets_encrypt"
    )
  end

  it "inicializa o pedido com status pending" do
    expect(order.status).to eq(:pending)
  end

  it "inicializa o pedido com zero tentativas de validação" do
    expect(order.validation_attempts).to eq(0)
  end

  it "armazena o domínio informado" do
    expect(order.domain).to eq("loja.exemplo.com.br")
  end

  it "armazena o provedor informado" do
    expect(order.provider).to eq("lets_encrypt")
  end
end