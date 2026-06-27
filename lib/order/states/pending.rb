class Order
  module States
    class Pending < Base
      private_class_method def self.handle(event, order)
        case event
        when "start_validation" then "validating"
        else super
        end
      end
    end
  end
end
