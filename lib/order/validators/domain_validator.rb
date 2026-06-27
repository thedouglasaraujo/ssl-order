class Order
  module Validators
    class DomainValidator
      REGEX = /\A(?:[a-z0-9](?:[a-z0-9\-]{0,61}[a-z0-9])?\.)+[a-z]{2,}\z/i.freeze

      def validate!(value)
        return if value.is_a?(String) && value.match?(REGEX)

        raise Order::InvalidDomain, "Dominio invalido: #{value.inspect}"
      end
    end
  end
end
