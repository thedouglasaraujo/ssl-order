RSpec.describe Order, "retry de validação" do
  subject(:order) { described_class.new(domain: "loja.exemplo.com.br", provider: "lets_encrypt") }

  before { order.apply(:start_validation) }

  it "incrementa validation_attempts a cada validate_fail" do
    expect { order.apply(:validate_fail) }
      .to change { order.validation_attempts }.from(0).to(1)

    expect { order.apply(:validate_fail) }
      .to change { order.validation_attempts }.from(1).to(2)
  end

  it "permanece em validating enquanto abaixo do limite" do
    (Order::MAX_VALIDATION_ATTEMPTS - 1).times { order.apply(:validate_fail) }

    expect(order.status).to eq("validating")
  end

  it "vai para failed exatamente ao atingir MAX_VALIDATION_ATTEMPTS" do
    Order::MAX_VALIDATION_ATTEMPTS.times { order.apply(:validate_fail) }

    expect(order.status).to eq("failed")
    expect(order.validation_attempts).to eq(Order::MAX_VALIDATION_ATTEMPTS)
  end

  it "não vai para failed antes do limite" do
    (Order::MAX_VALIDATION_ATTEMPTS - 1).times { order.apply(:validate_fail) }

    expect(order.status).not_to eq("failed")
  end

  it "aceita validate_ok após falhas que não esgotaram o limite" do
    (Order::MAX_VALIDATION_ATTEMPTS - 1).times { order.apply(:validate_fail) }
    order.apply(:validate_ok)

    expect(order.status).to eq("issued")
  end
end
