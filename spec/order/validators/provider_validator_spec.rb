RSpec.describe Order::Validators::ProviderValidator do
  subject(:validator) { described_class.new }

  describe "#validate!" do
    context "com provedores válidos" do
      it "não levanta erro para lets_encrypt" do
        expect { validator.validate!("lets_encrypt") }.not_to raise_error
      end

      it "não levanta erro para globalsign" do
        expect { validator.validate!("globalsign") }.not_to raise_error
      end
    end

    context "com provedores inválidos" do
      it "levanta InvalidProvider para provedor desconhecido" do
        expect { validator.validate!("digicert") }.to raise_error(Order::InvalidProvider)
      end

      it "levanta InvalidProvider para string vazia" do
        expect { validator.validate!("") }.to raise_error(Order::InvalidProvider)
      end

      it "levanta InvalidProvider para nil" do
        expect { validator.validate!(nil) }.to raise_error(Order::InvalidProvider)
      end

      it "a mensagem lista os provedores aceitos" do
        expect { validator.validate!("outro") }
          .to raise_error(Order::InvalidProvider, /lets_encrypt.*globalsign/)
      end
    end
  end
end
