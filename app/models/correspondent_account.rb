class CorrespondentAccount < ApplicationRecord
  validates :amount, presence: true
  validates :amount, numericality: { less_than_or_equal_to: 0 }

  def self.current_amount
    last.amount.to_f
  end
end
