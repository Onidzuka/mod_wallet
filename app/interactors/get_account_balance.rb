class GetAccountBalance
  include Interactor

  def call
    begin
      self.account = Account.find_by_identity_number!(context.account_id)
      raise_if_account_closed
      get_balance
    rescue StandardError => e
      context.fail!(message: e)
    end
  end

  private

  attr_accessor :account

  def raise_if_account_closed
    raise Exceptions::AccountClosed if account.closed?
  end

  def get_balance
    context[:balance] = {
      current_balance_amount:   account.current_balance_amount.to_s,
      held_balance_amount:      account.held_balance_amount.to_s,
      available_balance_amount: account.available_balance_amount.to_s
    }
  end
end
