class HeldBalance < ApplicationRecord
  belongs_to :account
  belongs_to :document

  validates :account,  presence: true
  validates :document, presence: true
end
