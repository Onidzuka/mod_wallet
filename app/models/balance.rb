class Balance < ApplicationRecord
  belongs_to :account
  belongs_to :document

  validates :account,  presence: true
  validates :amount,   presence: true
  validates :account,  presence: true
  validates :document, presence: true
  validates :amount,   numericality: { greater_than_or_equal_to: 0 }
end
