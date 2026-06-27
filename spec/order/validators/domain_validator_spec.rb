RSpec.describe Order::Validators::DomainValidator do
  subject(:validator) { described_class.new }

  describe "#validate!" do
    context "com domínios válidos" do
      it "não levanta erro para domínio simples" do
        expect { validator.validate!("exemplo.com") }.not_to raise_error
      end

      it "não levanta erro para domínio com subdomínio" do
        expect { validator.validate!("loja.exemplo.com.br") }.not_to raise_error
      end

      it "não levanta erro para múltiplos subdomínios" do
        expect { validator.validate!("mail.srv.empresa.com.br") }.not_to raise_error
      end

      it "não levanta erro para TLD de dois caracteres" do
        expect { validator.validate!("site.io") }.not_to raise_error
      end
    end

    context "com domínios inválidos" do
      it "levanta InvalidDomain para string vazia" do
        expect { validator.validate!("") }.to raise_error(Order::InvalidDomain)
      end

      it "levanta InvalidDomain sem ponto (sem TLD)" do
        expect { validator.validate!("locaweb") }.to raise_error(Order::InvalidDomain)
      end

      it "levanta InvalidDomain com espaço no meio" do
        expect { validator.validate!("meu site.com") }.to raise_error(Order::InvalidDomain)
      end

      it "levanta InvalidDomain para nil" do
        expect { validator.validate!(nil) }.to raise_error(Order::InvalidDomain)
      end

      it "levanta InvalidDomain para inteiro" do
        expect { validator.validate!(123) }.to raise_error(Order::InvalidDomain)
      end
    end
  end
end
