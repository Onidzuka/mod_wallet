class BlockAccount
  include Interactor

  def call
    begin
      assign_attributes
      raise_if_account_closed
      if operations
        block_account_operations
      else
        raise Exceptions::InvalidRequest
      end
    rescue StandardError => e
      context.fail!(message: e)
    end
  end

  private

  attr_accessor :account, :operations

  def assign_attributes
    self.account = Account.find_by_identity_number!(context.params[:account_id])
    self.operations = context.params[:operations]
  end

  def block_account_operations
    ActiveRecord::Base.transaction do
      operations.each do |operation|
        account.blocked_operations.create!(operation: operation) unless account.blocked?(operation)
      end
    end
  end

  def raise_if_account_closed
    raise Exceptions::AccountClosed if account.closed?
  end
end
