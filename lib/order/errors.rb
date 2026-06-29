class Order
  class InvalidTransition < StandardError; end
  class InvalidDomain     < ArgumentError;  end
  class InvalidProvider   < ArgumentError;  end
end
