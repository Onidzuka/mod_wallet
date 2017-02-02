class AccountsController < ApplicationController
  def create
    use_case = CreateAccount.call(params: account_params)
    if use_case.success?
      render json: {account_id: use_case.account.identity_number, status: 'success'}, status: :ok
    else
      render json: {status: 'error', message: use_case.message}, status: :bad_request
    end
  end

  def close
    use_case = CloseAccount.call(account_id: account_id)
    if use_case.success?
      render json: {status: 'success'}, status: :ok
    else
      render json: {status: 'error', message: use_case.message}, status: :bad_request
    end
  end

  def block
    use_case = BlockAccount.call(params: account_operations_params)
    if use_case.success?
      render json: {status: 'success'}, status: :ok
    else
      render json: {status: 'error', message: use_case.message}, status: :bad_request
    end
  end

  def unblock
    use_case = UnblockAccount.call(params: account_operations_params)
    if use_case.success?
      render json: {status: 'success'}, status: :ok
    else
      render json: {status: 'error', message: use_case.message}, status: :bad_request
    end
  end

  def balance
    use_case = GetAccountBalance.call(account_id: account_id)
    if use_case.success?
      render json: {status: 'success', balance: use_case.balance}, status: :ok
    else
      render json: {status: 'error', message: use_case.message}, status: :bad_request
    end
  end

  def history
    use_case = GetAccountHistory.call(params: account_history_params)
    if use_case.success?
      render json: {status: 'success', history: use_case[:history]}, status: :ok
    else
      render json: {status: 'error', message: use_case.message}, status: :bad_request
    end
  end

  def history_dates
    use_case = GetHistoryDates.call(params: history_dates_params)
    if use_case.success?
      render json: {status: 'success', dates: use_case[:dates]}, status: :ok
    else
      render json: {status: 'error', message: use_case.message}, status: :bad_request
    end
  end

  private

  def account_id
    _params = params.permit(:account_id)
    _params[:account_id]
  end

  def account_params
    params.permit(:account_id, :country_code, account_type: [])
  end

  def account_operations_params
    params.permit(:account_id, operations: [])
  end

  def account_history_params
    params.permit(:account_id, :limit, :start_date, :end_date)
  end

  def history_dates_params
    params.permit(:account_id, :year)
  end
end
