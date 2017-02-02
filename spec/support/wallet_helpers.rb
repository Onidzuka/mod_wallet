module WallerHelpers

  def create_document(params = {})
    post :create, params: params
    Document.find_by_document_number!(params[:id].to_i)
  end

end
