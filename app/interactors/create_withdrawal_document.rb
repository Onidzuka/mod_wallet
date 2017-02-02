class CreateWithdrawalDocument
  include AASM
  include HasFolder

  attr_accessor :account, :document

  def initialize(document)
    self.document = document
    self.document.folder = find_or_create_folder!(folder_id)
    self.account  = Account.find_by_identity_number(account_id)
  end

  aasm do
    state :pending, initial: true
    state :validating_account,    after_enter: :validate_account
    state :validating_document,   after_enter: :validate_document
    state :document_valid,        after_enter: :hold_balance
    state :saving_document,       after_enter: :save_valid_document
    state :document_invalid,      after_enter: :save_invalid_document

    event :create do
      transitions from: :pending, to: :validating_account
    end

    event :account_valid do
      transitions from: :validating_account,  to: :validating_document
    end

    event :valid_document do
      transitions from: :validating_document, to: :document_valid
    end

    event :save_document do
      transitions from: :document_valid,      to: :saving_document
    end

    event :invalid_document do
      transitions from: :validating_account,  to: :document_invalid
      transitions from: :validating_document, to: :document_invalid
    end
  end

  def validate_account
    check_account
    self.account_valid
  end

  def validate_document
    assign_attributes
    raise_if_document_invalid
    raise_if_insufficient_balance
    self.valid_document
  end

  def hold_balance
    account.held_balances.create!(amount: withdrawal_amount, document: document)
    self.save_document
  end

  def save_valid_document
    document.save!
  end

  def save_invalid_document
    document.tap do |document|
      document.status          = 'invalid'
      document.document_type   = document_type
      document.document_number = document_id
      document.save(validate: false)
    end
  end

  private

  def check_account
    raise Exceptions::AccountNotFound if account.nil?
    raise Exceptions::AccountClosed   if account.closed?
    raise Exceptions::AccountBlocked  if account.blocked?
  end

  def assign_attributes
    document.status = 'created'
    document.document_number   = document_id
    document.document_type     = document_type
    document.amount            = withdrawal_amount
    document.target_account_id = account.id
  end

  def account_id
    document.params['params']['target_account_id']
  end

  def has_insufficient_balance?
    account.available_balance_amount < withdrawal_amount.to_f
  end

  def raise_if_insufficient_balance
    raise Exceptions::InsufficientBalance if has_insufficient_balance?
  end

  def raise_if_document_invalid
    raise Exceptions::InvalidDocument unless document.valid?
  end

  def folder_id
    document.params['folder_id']
  end

  def document_id
    document.params['id']
  end

  def document_type
    document.params['type']
  end

  def withdrawal_amount
    document.params['params']['amount']
  end
end
