class CreateEmissionDocument
  include AASM
  include HasFolder

  attr_accessor :account, :document

  def initialize(document)
    self.document = document
    self.account = Account.find_by_identity_number(account_id)
    self.document.folder = find_or_create_folder!(folder_id)
  end

  aasm do
    state :pending, initial: true
    state :validating_account,        after_enter: :validate_account
    state :validating_document,       after_enter: :validate_document
    state :document_invalid,          after_enter: :save_invalid_document
    state :document_created,          after_enter: :save_valid_document

    event :create do
      transitions from: :pending,             to: :validating_account
    end

    event :account_valid do
      transitions from: :validating_account,  to: :validating_document
    end

    event :document_valid do
      transitions from: :validating_document, to: :document_created
    end

    event :invalid_document do
      transitions from: :validating_account,  to: :document_invalid
      transitions from: :validating_document, to: :document_invalid
    end
  end

  def validate_account
    self.account_valid if account_valid?
  end

  def validate_document
    assign_attributes
    raise_if_document_invalid
    self.document_valid
  end

  def save_invalid_document
    document.tap do |document|
      document.status          = 'invalid'
      document.document_type   = document_type
      document.document_number = document_id
      document.save(validate: false)
    end
  end

  def save_valid_document
    document.save!
  end

  private

  def account_valid?
    raise Exceptions::AccountNotFound       if account.nil?
    raise Exceptions::AccountClosed         if account.closed?
    raise Exceptions::AccountBlocked        if account.blocked?
    raise Exceptions::AccountTypeIsNotAgent unless account.has_role?(:agent)
    true
  end

  def assign_attributes
    document.status = 'created'
    document.document_number   = document_id
    document.document_type     = document_type
    document.amount            = emission_amount
    document.target_account_id = account.id
  end

  def raise_if_document_invalid
    raise Exceptions::InvalidDocument unless document.valid?
  end

  def account_id
    document.params['params']['target_account_id']
  end

  def document_id
    document.params['id']
  end

  def folder_id
    document.params['folder_id']
  end

  def document_type
    document.params['type']
  end

  def emission_amount
    document.params['params']['amount']
  end
end
