class CloseAccount
  include Interactor

  def call
    begin
      account = Account.find_by_identity_number!(context.account_id)
      account.update_attribute(:closed, true)
    rescue StandardError => e
      context.fail!(message: e)
    end
  end
end
