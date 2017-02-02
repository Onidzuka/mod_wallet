class BlockedOperation < ApplicationRecord
  belongs_to :account

  validates :account,   presence: true
  validates :operation, presence: true, inclusion: { in: %w(credit debit), message: 'invalid' }
end
