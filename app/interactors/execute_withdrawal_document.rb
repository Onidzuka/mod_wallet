class ExecuteWithdrawalDocument
  include AASM

  attr_accessor :document

  def initialize(document)
    self.document = document
  end

  aasm do
    state :pending, initial: true
    state :processing_withdrawal, after_enter: :withdraw_money
    state :withdrawal_success

    event :execute do
      transitions from: :pending, to: :processing_withdrawal
    end

    event :withdrawal_succeeded do
      transitions from: :processing_withdrawal, to: :withdrawal_success
    end
  end

  def withdraw_money
    ActiveRecord::Base.transaction do
      target_account.lock!
      check_withdrawal
      debit_account
      update_correspondent_balance
      update_document
      self.withdrawal_succeeded
    end
  end

  private

  def update_document
    document.tap do |document|
      document.status = 'executed'
      document.save!
    end
  end

  def check_withdrawal
    raise Exceptions::InsufficientBalance unless has_enough_amount_to_withdraw?
    raise Exceptions::InvalidTransfer unless held_amount_cleared?
  end

  def debit_account
    new_balance = target_account.current_balance_amount - withdrawal_amount
    target_account.balances.create!(amount: new_balance, document: document)
  end

  def update_correspondent_balance
    new_correspondent_balance = (CorrespondentAccount.current_amount.abs - withdrawal_amount) * -1
    CorrespondentAccount.create!(amount: new_correspondent_balance)
  end

  def has_enough_amount_to_withdraw?
    !(target_account.available_balance_amount < withdrawal_amount || target_account.current_balance_amount < withdrawal_amount)
  end

  def available_balance_to_withraw
    (target_account.current_balance_amount - target_account.held_balance_amount_excluding_current_transfer(document)).round(2)
  end

  def target_account
    document.target_account
  end

  def withdrawal_amount
    document.amount.to_f
  end

  def held_amount_cleared?
    document.held_balance_cleared?
  end
end
