class Account < ApplicationRecord
  rolify

  has_many :balances
  has_many :held_balances
  has_many :blocked_operations
  has_many :source_documents, class_name: Document, foreign_key: :source_account_id
  has_many :target_documents, class_name: Document, foreign_key: :target_account_id

  validates :identity_number, :country_code, presence: true
  validates :closed, inclusion: { in: [true, false] }
  validates :identity_number, uniqueness: true

  def current_balance_amount
    if balances.exists?
      balances.last.amount.to_f
    else
      0.0
    end
  end

  def available_balance_amount
    (current_balance_amount - held_balance_amount).round(2)
  end

  def held_balance_amount
    (held_balances.sum('amount').to_f).round(2)
  end

  def has_held_amount?
    held_balances.any?
  end

  def held_balance_amount_excluding_current_transfer(document)
    (held_balances.where.not(document_id: document.id).sum(:amount).to_f).round(2)
  end

  def blocked?(*args)
    if args.empty?
      blocked_operations.where(operation: ['credit', 'debit']).exists?
    elsif one_argument?(args)
      blocked_operations.where(operation: args).exists?
    else
      raise ArgumentError
    end
  end

  class << self
    def generate_base58
      rand_numbers = (1..10).to_a.shuffle.join.to_i
      Base58.encode(rand_numbers)
    end
  end

  private

  def one_argument?(args)
    args.size == 1
  end

end
