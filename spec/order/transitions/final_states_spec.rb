RSpec.describe Order, "estados finais" do
  subject(:order) { described_class.new(domain: "loja.exemplo.com.br", provider: "lets_encrypt") }

  ALL_EVENTS = %i[start_validation validate_ok validate_fail install cancel].freeze

  shared_examples "bloqueia todos os eventos" do
    it "reporta final? como true" do
      expect(order.final?).to be true
    end

    ALL_EVENTS.each do |event|
      it "recusa :#{event}" do
        expect { order.apply(event) }.to raise_error(Order::InvalidTransition)
      end
    end
  end

  context "quando installed" do
    before do
      order.apply(:start_validation)
      order.apply(:validate_ok)
      order.apply(:install)
    end

    include_examples "bloqueia todos os eventos"
  end

  context "quando failed por cancel" do
    before { order.apply(:cancel) }

    include_examples "bloqueia todos os eventos"
  end

  context "quando failed por esgotar tentativas" do
    before do
      order.apply(:start_validation)
      Order::MAX_VALIDATION_ATTEMPTS.times { order.apply(:validate_fail) }
    end

    include_examples "bloqueia todos os eventos"
  end

  context "estados não-finais" do
    it "pending não é final" do
      expect(order.final?).to be false
    end

    it "validating não é final" do
      order.apply(:start_validation)
      expect(order.final?).to be false
    end

    it "issued não é final" do
      order.apply(:start_validation)
      order.apply(:validate_ok)
      expect(order.final?).to be false
    end
  end
end
