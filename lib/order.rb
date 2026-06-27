class Order
  attr_reader :domain, :provider, :status, :validation_attempts

  def initialize(domain:, provider:)
    @domain = domain
    @provider = provider
    @status = "pending"
    @validation_attempts = 0
  end
end