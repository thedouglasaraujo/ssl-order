require_relative "order/errors"
require_relative "order/validators/domain_validator"
require_relative "order/validators/provider_validator"
require_relative "order/states/base"
require_relative "order/states/pending"
require_relative "order/states/validating"
require_relative "order/states/issued"
require_relative "order/states/final_state"
require_relative "order/states/installed"
require_relative "order/states/failed"

class Order
  MAX_VALIDATION_ATTEMPTS = 3

  attr_reader :domain, :provider, :status, :validation_attempts

  STATES = {
    pending: States::Pending,
    validating: States::Validating,
    issued: States::Issued,
    installed: States::Installed,
    failed: States::Failed
  }.freeze

  def initialize(domain:, provider:)
    Validators::DomainValidator.new.validate!(domain)
    Validators::ProviderValidator.new.validate!(provider)

    @domain = domain
    @provider = provider
    @status = :pending
    @validation_attempts = 0
  end

  def apply(event)
    event = event.to_sym

    new_status = current_state.apply(event, self)

    @validation_attempts += 1 if event == :validate_fail
    @status = new_status
  end

  def final?
    current_state.final?
  end

  private

  def current_state
    STATES.fetch(@status) do
      raise Order::InvalidTransition,
            "Estado desconhecido: #{@status.inspect}"
    end
  end
end