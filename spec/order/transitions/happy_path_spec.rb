RSpec.describe Order, "caminho feliz" do
  subject(:order) { described_class.new(domain: "loja.exemplo.com.br", provider: "lets_encrypt") }

  it "percorre pending → validating ao aplicar start_validation" do
    expect { order.apply(:start_validation) }
      .to change { order.status }.from("pending").to("validating")
  end

  it "percorre validating → issued ao aplicar validate_ok" do
    order.apply(:start_validation)
    expect { order.apply(:validate_ok) }
      .to change { order.status }.from("validating").to("issued")
  end

  it "percorre issued → installed ao aplicar install" do
    order.apply(:start_validation)
    order.apply(:validate_ok)
    expect { order.apply(:install) }
      .to change { order.status }.from("issued").to("installed")
  end

  it "retorna o novo status após cada evento" do
    expect(order.apply(:start_validation)).to eq("validating")
    expect(order.apply(:validate_ok)).to eq("issued")
    expect(order.apply(:install)).to eq("installed")
  end

  it "não incrementa validation_attempts no caminho sem falhas" do
    order.apply(:start_validation)
    order.apply(:validate_ok)
    order.apply(:install)
    expect(order.validation_attempts).to eq(0)
  end
end
