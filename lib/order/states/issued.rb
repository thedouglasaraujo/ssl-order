class Order
  module States
    class Issued < Base
      private_class_method def self.handle(event, order)
        case event
        when :install then "installed"
        else super
        end
      end
    end
  end
end
