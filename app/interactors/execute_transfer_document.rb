class ExecuteTransferDocument
  include AASM

  attr_accessor :document

  def initialize(document)
    self.document = document
  end

  aasm do
    state :pending, initial: true
    state :processing_transfer, after_enter: :transfer_funds
    state :transfer_success

    event :execute do
      transitions from: :pending, to: :processing_transfer
    end

    event :transfer_succeeded do
      transitions from: :processing_transfer, to: :transfer_success
    end
  end

  def transfer_funds
    ActiveRecord::Base.transaction do
      lock_accounts
      check_transfer
      debit_account
      credit_account
      update_document
      self.transfer_succeeded
    end
  end

  private

  def lock_accounts
    source_account.lock!
    target_account.lock!
  end

  def check_transfer
    raise Exceptions::InsufficientBalance unless has_enough_amount_to_transfer?
    raise Exceptions::InvalidTransfer     unless held_amount_cleared?
  end

  def update_document
    document.tap do |document|
      document.status = 'executed'
      document.save!
    end
  end

  def debit_account
    new_balance = current_balance_amount(source_account) - transfer_amount
    source_account.balances.create!(amount: new_balance, document: document)
  end

  def credit_account
    new_balance = current_balance_amount(target_account) + transfer_amount
    target_account.balances.create!(amount: new_balance, document: document)
  end

  def has_enough_amount_to_transfer?
    !(available_balance_to_transfer < transfer_amount || current_balance_amount(source_account) < transfer_amount)
  end

  def held_amount_cleared?
    document.held_balance_cleared?
  end

  def source_account
    document.source_account
  end

  def target_account
    document.target_account
  end

  def available_balance_to_transfer
    (current_balance_amount(source_account) - held_balance_amount_excluding_current_transfer(source_account)).round(2)
  end

  def transfer_amount
    document.amount.to_f
  end

  def current_balance_amount(account)
    account.current_balance_amount
  end

  def held_balance_amount_excluding_current_transfer(account)
    account.held_balance_amount_excluding_current_transfer(document)
  end
end
