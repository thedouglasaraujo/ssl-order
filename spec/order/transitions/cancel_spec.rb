RSpec.describe Order, "evento :cancel" do
  subject(:order) { described_class.new(domain: "loja.exemplo.com.br", provider: "lets_encrypt") }

  it "cancela a partir de pending" do
    expect { order.apply(:cancel) }
      .to change { order.status }.from("pending").to("failed")
  end

  it "cancela a partir de validating" do
    order.apply(:start_validation)
    expect { order.apply(:cancel) }
      .to change { order.status }.from("validating").to("failed")
  end

  it "cancela a partir de issued" do
    order.apply(:start_validation)
    order.apply(:validate_ok)
    expect { order.apply(:cancel) }
      .to change { order.status }.from("issued").to("failed")
  end

  it "retorna 'failed' ao cancelar" do
    expect(order.apply(:cancel)).to eq("failed")
  end
end
