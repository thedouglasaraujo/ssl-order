class Order
  module Validators
    class ProviderValidator
      VALID_PROVIDERS = %w[lets_encrypt globalsign].freeze

      def validate!(value)
        return if VALID_PROVIDERS.include?(value)

        raise Order::InvalidProvider,
          "Provedor invalido: #{value.inspect} (aceitos: #{VALID_PROVIDERS.join(', ')})"
      end
    end
  end
end
