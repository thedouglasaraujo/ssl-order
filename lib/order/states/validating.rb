class Order
  module States
    class Validating < Base
      private_class_method def self.handle(event, order)
        case event
        when :validate_ok
          "issued"
        when :validate_fail
          next_attempts = order.validation_attempts + 1
          next_attempts >= Order::MAX_VALIDATION_ATTEMPTS ? "failed" : "validating"
        else
          super
        end
      end
    end
  end
end
