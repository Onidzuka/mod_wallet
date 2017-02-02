class CreateAccount
  include Interactor

  ALLOWED_ACCOUNT_TYPES = %w(corporate agent merchant individual)

  def call
    begin
      create_account
    rescue StandardError => e
      context.fail!(message: e)
    end
  end

  private

  def create_account
    account_types = context.params[:account_type]
    unless eligible_account_type?(account_types) && save_account(account_types)
      raise Exceptions::InvalidRequest
    end
  end

  def eligible_account_type?(account_types)
    account_types_exists?(account_types) && account_types_allowed?(account_types)
  end

  def save_account(account_types)
    context[:account] = Account.new(account_params)
    if context[:account].save!
      account_types.each { |account_type| context[:account].add_role account_type }
    end
  end

  def account_params
    _params = context.params.slice(:account_id, :country_code)
    _params[:account_id] = encode_to_base58(_params[:account_id])
    _params[:identity_number] = _params.delete(:account_id)
    _params
  end

  def account_types_exists?(account_types)
    !account_types.nil? && account_types.any?
  end

  def account_types_allowed?(account_types)
    account_types.each do |account_type|
      raise Exceptions::InvalidAccountType unless ALLOWED_ACCOUNT_TYPES.include?(account_type)
    end
    true
  end

  def encode_to_base58(iin)
    Base58.encode(iin.to_i) if iin.present?
  end
end
