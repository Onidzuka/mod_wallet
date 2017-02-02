class DocumentsController < ApplicationController
  def create
    begin
      use_case = CreateDocument.call(params: create_document_params)
      if use_case.success?
        render json: {status: 'success'}, status: :ok
      else
        render json: {status: 'error', message: use_case.message} , status: :bad_request
      end
    rescue StandardError => e
      render json: {status: 'error', message: e}, status: :bad_request
    end
  end

  def execute
    begin
      use_case = ExecuteDocument.call(document_number: document_number)
      if use_case.success?
        render json: {status: 'success'}, status: :ok
      else
        render json: {status: 'error', message: use_case.message}, status: :bad_request
      end
    rescue StandardError => e
      render json: {status: 'error', message: e}, status: :bad_request
    end
  end

  def cancel
    begin
      use_case = CancelDocument.call(folder_id: folder_id)
      if use_case.success?
        render json: {status: 'success'}, status: :ok
      else
        render json: {status: 'error', message: use_case.message}, status: :bad_request
      end
    rescue StandardError => e
      render json: {status: 'error', message: e}, status: :bad_request
    end
  end

  private

  def create_document_params
    _params = get_permitted_params
    if emission_or_withdrawal?(_params[:type])
      remove_not_needed_params(_params)
      _params
    elsif transfer?(_params[:type])
      _params
    else
      raise Exceptions::InvalidDocumentType
    end
  end

  def get_permitted_params
    target_params = params.fetch(:target, {}).try(:permit!)
    _params = params.permit(
        :id,
        :folder_id,
        :type,
        :params => [
            :amount,
            :source_account_id,
            :target_account_id,
        ]
    ).merge(target: target_params)
  end

  def remove_not_needed_params(_params)
    _params.tap do |params|
      params[:params].delete(:source_account_id)
      params[:target].delete(:source_message)
    end
  end

  def document_number
    _params = params.permit(:id)
    _params[:id]
  end

  def folder_id
    _params = params.permit(:id)
    _params[:id]
  end

  def emission_or_withdrawal?(document_type)
    document_type == 'emission' || document_type == 'withdrawal'
  end

  def transfer?(document_type)
    document_type == 'transfer'
  end
end
