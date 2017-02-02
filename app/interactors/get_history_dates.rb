class GetHistoryDates
  include Interactor

  attr_accessor :account

  def call
    begin
      self.account = Account.find_by_identity_number!(context.params[:account_id])
      get_dates
    rescue StandardError => e
      context.fail!(message: e)
    end
  end

  private

  def get_dates
    context.dates = account_operations
                        .where(status: 'executed')
                        .select("to_char(created_at, 'YYYY-MM-DD') as processed_on")
                        .group("date_part('year', created_at), processed_on")
                        .having("date_part('year', created_at) = ?", context.params[:year]).to_a.collect(&:processed_on)
  end

  def account_operations
    account.source_documents.or(account.target_documents)
  end
end
