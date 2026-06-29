RSpec.describe Order, "transições inválidas" do
  subject(:order) { described_class.new(domain: "loja.exemplo.com.br", provider: "lets_encrypt") }

  shared_examples "rejeita o evento sem mudar o estado" do |event|
    it "recusa :#{event} sem alterar o status" do
      status_antes = order.status
      expect { order.apply(event) }.to raise_error(Order::InvalidTransition)
      expect(order.status).to eq(status_antes)
    end
  end

  context "quando pending" do
    include_examples "rejeita o evento sem mudar o estado", :install
    include_examples "rejeita o evento sem mudar o estado", :validate_ok
    include_examples "rejeita o evento sem mudar o estado", :validate_fail
  end

  context "quando validating" do
    before { order.apply(:start_validation) }

    include_examples "rejeita o evento sem mudar o estado", :start_validation
    include_examples "rejeita o evento sem mudar o estado", :install
  end

  context "quando issued" do
    before do
      order.apply(:start_validation)
      order.apply(:validate_ok)
    end

    include_examples "rejeita o evento sem mudar o estado", :start_validation
    include_examples "rejeita o evento sem mudar o estado", :validate_ok
    include_examples "rejeita o evento sem mudar o estado", :validate_fail
  end

  it "recusa evento completamente desconhecido" do
    expect { order.apply(:evento_fantasma) }.to raise_error(Order::InvalidTransition)
  end

  it "a mensagem menciona o evento e o estado atual" do
    expect { order.apply(:install) }
      .to raise_error(Order::InvalidTransition, /install.*pending/)
  end
end
