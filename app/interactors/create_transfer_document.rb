class CreateTransferDocument
  include AASM
  include HasFolder

  attr_accessor :document, :source_account, :target_account

  def initialize(document)
    self.document = document
    self.source_account = Account.find_by_identity_number(document.params['params']['source_account_id'])
    self.target_account = Account.find_by_identity_number(document.params['params']['target_account_id'])
  end

  aasm do
    state :pending,             initial: true
    state :validating_transfer, after_enter: :validate_transfer
    state :document_valid,      after_enter: :hold_balance
    state :saving_document,     after_enter: :save_valid_document
    state :document_invalid,    after_enter: :save_invalid_document

    event :create do
      transitions from: :pending, to: :validating_transfer
    end

    event :valid_document do
      transitions from: :validating_transfer, to: :document_valid
    end

    event :save_document do
      transitions from: :document_valid,      to: :saving_document
    end

    event :invalid_document do
      transitions from: :validating_transfer, to: :document_invalid
    end
  end

  def validate_transfer
    self.valid_document if valid_transfer?
  end

  def hold_balance
    ActiveRecord::Base.transaction do
      source_account.lock!
      source_account.held_balances.create!(account: source_account, amount: transfer_amount, document: document)
      self.save_document
    end
  end

  def save_invalid_document
    folder = find_or_create_folder!(folder_id)
    document.tap do |document|
      document.status          = 'invalid'
      document.document_type   = document_type
      document.document_number = document_id
      document.folder          = folder
      document.save(validate: false)
    end
  end

  def save_valid_document
    folder = find_or_create_folder!(folder_id)
    document.tap do |document|
      assign_attributes(document)
      document.folder = folder
      document.save!
    end
  end

  private

  def valid_transfer?
    raise Exceptions::SourceAccountNotFound if source_account.nil?
    raise Exceptions::TargetAccountNotFound if target_account.nil?
    raise Exceptions::SelfSelectionTransfer if self_selection_transfer?
    raise Exceptions::SourceAccountBlocked  if source_account.blocked?
    raise Exceptions::TargetAccountBlocked  if target_account.blocked?
    raise Exceptions::SourceAccountClosed   if source_account.closed?
    raise Exceptions::TargetAccountClosed   if target_account.closed?
    raise Exceptions::InsufficientBalance   if has_insufficient_balance?
    raise Exceptions::ForbiddenTransfer     if forbidden_transfer?
    raise Exceptions::TransferLimitExceeded if transfer_limit_exceeded? && from_individual_to_individual?
    true
  end

  def transfer_limit_exceeded?
    transfer_amount.to_f >= transfer_limit
  end

  def forbidden_transfer?
    !(from_agent_to_individual? || from_individual_to_individual? || from_individual_to_merchant?)
  end

  def assign_attributes(document)
    document.status            = 'created'
    document.document_type     = 'transfer'
    document.amount            = transfer_amount
    document.document_number   = document_id
    document.source_account_id = source_account.id
    document.target_account_id = target_account.id
  end

  def has_insufficient_balance?
    source_account.available_balance_amount < transfer_amount.to_f
  end

  def self_selection_transfer?
    source_account.id == target_account.id
  end

  def from_individual_to_merchant?
    source_account.has_role?(:individual) && target_account.has_role?(:merchant)
  end

  def from_individual_to_individual?
    source_account.has_role?(:individual) && target_account.has_role?(:individual)
  end

  def from_agent_to_individual?
    source_account.has_role?(:agent) && target_account.has_role?(:individual)
  end

  def transfer_amount
    document.params['params']['amount']
  end

  def folder_id
    document.params['folder_id']
  end

  def document_id
    document.params['id'].to_i
  end

  def document_type
    document.params['type']
  end

  def transfer_limit
    ModWallet::Application.config.transfer_limit
  end
end
