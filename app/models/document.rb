class Document < ApplicationRecord
  has_one :held_balance
  has_many :balances

  belongs_to :source_account, class_name: Account, optional: true
  belongs_to :target_account, class_name: Account, optional: true
  belongs_to :folder

  STATUSES = %w(created invalid canceled executed failed)
  DOCUMENT_TYPES = %w(emission withdrawal transfer)

  validates :params, :status, :document_type, :document_number, :amount, presence: true
  validates :status, inclusion: {in: STATUSES, message: 'invalid status'}
  validates :document_type, inclusion: {in: DOCUMENT_TYPES, message: 'invalid document type'}
  validates :source_account_id, :target_account_id, numericality: true, allow_nil: true
  validates :document_number, numericality: {greater_than: 0}, uniqueness: true
  validates :amount, numericality: {greater_than: 0}
  validates :folder, presence: true

  def created?
    status == 'created'
  end

  def held_balance_cleared?
    if held_balance.blank?
      true
    else
      held_balance.destroy
      held_balance.destroyed?
    end
  end

  def has_held_amount?
    !held_balance.nil?
  end
end
