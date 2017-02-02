class ExecuteEmissionDocument
  include AASM

  attr_accessor :document

  def initialize(document)
    self.document = document
  end

  aasm do
    state :pending,             initial: true
    state :processing_emission, after_enter: :emit_money
    state :emission_success

    event :execute do
      transitions from: :pending,             to: :processing_emission
    end

    event :emission_succeeded do
      transitions from: :processing_emission, to: :emission_success
    end
  end

  def emit_money
    ActiveRecord::Base.transaction do
      credit_account
      update_correspondent_balance
      update_document
      self.emission_succeeded
    end
  end

  private

  def update_correspondent_balance
    new_correspondent_balance = CorrespondentAccount.current_amount - emission_amount
    CorrespondentAccount.create!(amount: new_correspondent_balance)
  end

  def credit_account
    new_balance = target_account.current_balance_amount + emission_amount
    balances.create!(account: target_account, amount: new_balance)
  end

  def update_document
    document.tap do |document|
      document.status = 'executed'
      document.save!
    end
  end

  def target_account
    document.target_account
  end

  def emission_amount
    document.amount.to_f
  end

  def balances
    document.balances
  end
end
