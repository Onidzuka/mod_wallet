class CreateDocument
  include Interactor

  def call
    begin
      document = Document.new(params: context.params)

      create_document = CreateDocumentFactory.new(document).get_document
      create_document.create
    rescue StandardError => e
      create_document.invalid_document if create_document
      document.update_attribute(:reason, e.message)
      context.fail!(message: {code: e.message, errors: error_messages(document)})
    end
  end

  private

  def error_messages(document)
    document.errors.full_messages.join(', ')
  end
end
