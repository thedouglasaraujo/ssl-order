class Order
  module States
    class Failed < Base
      def self.apply(event, order)
        raise Order::InvalidTransition, "Pedido já está em estado final: #{order.status}"
      end

      def self.final?
        true
      end
    end
  end
end
