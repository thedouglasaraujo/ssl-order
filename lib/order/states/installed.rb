class Order
  module States
    class Installed < Base
      def self.apply(event, order)
        raise Order::InvalidTransition, "Pedido já está em estado final: #{order.status}"
      end

      def self.final?
        true
      end
    end
  end
end
