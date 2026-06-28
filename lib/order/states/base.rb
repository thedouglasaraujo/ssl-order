class Order
  module States
    class Base
      def self.apply(event, order)
        return :failed if event == :cancel

        handle(event, order)
      end

      def self.final?
        false
      end

      private_class_method def self.handle(event, order)
        raise Order::InvalidTransition,
          "Evento '#{event}' não é permitido no estado '#{order.status}'"
      end
    end
  end
end
