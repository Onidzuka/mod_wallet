class GetAccountHistory
  include Interactor

  def call
    begin
      check_account
      get_account_history(limit, start_date, end_date)
    rescue StandardError => e
      context.fail!(message: e)
    end
  end

  private

  attr_accessor :account

  def get_account_history(limit = 10, start_date = nil, end_date = nil)
    if account_operations.present?
      operations = account_operations.where(status: 'executed').order(id: :desc).limit(limit)
      operations = operations.where(created_at: start_date..end_date) if date_params_given?(end_date, start_date)
      assign_values(operations)
    else
      context[:history] = []
    end
  end

  def assign_values(operations)
    context[:history] = account_history(operations)
  end

  def date_params_given?(end_date, start_date)
    start_date.present? && end_date.present?
  end

  def check_account
    self.account = Account.find_by_identity_number!(account_id)
    raise Exceptions::AccountClosed if account.closed?
  end

  def account_history(operations)
    operations.to_a.map do |operation|
      if emission_or_withdrawal?(operation.document_type)
        {
          document_id: operation.document_number.to_s,
          amount: formatted_amount(operation).to_s,
          message: message(operation),
          executed_at: operation.created_at,
        }
      else
        {
          document_id: operation.document_number.to_s,
          amount: formatted_amount(operation).to_s,
          message: message(operation),
          executed_at: operation.created_at,
        }
      end
    end
  end

  def formatted_amount(operation)
    amount = operation.amount
    if withdrawal?(operation.document_type) || (transfer?(operation.document_type) && sender?(operation.source_account_id))
      amount = -operation.amount
    end
    amount
  end

  def message(operation)
    sender?(operation.source_account_id) ? operation.params['target']['source_message'] : operation.params['target']['target_message']
  end

  def account_operations
    account.source_documents.or(account.target_documents)
  end

  def withdrawal?(document_type)
    document_type == 'withdrawal'
  end

  def sender?(account_id)
    account.id == account_id
  end

  def transfer?(document_type)
    document_type == 'transfer'
  end

  def emission_or_withdrawal?(document_type)
    document_type == 'withdrawal' || document_type == 'emission'
  end

  def limit
    context.params[:limit].to_i
  end

  def start_date
    context.params[:start_date]
  end

  def end_date
    context.params[:end_date]
  end

  def account_id
    context.params[:account_id]
  end
end
