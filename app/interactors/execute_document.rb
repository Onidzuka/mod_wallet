class ExecuteDocument
  include Interactor

  def call
    begin
      document = ExecuteDocumentFactory.new.get_document(context.document_number)
      document.execute
    rescue StandardError => e
      document.execution_failed if document
      # TODO save exception message in Document table, column reason
      context.fail!(message: {code: e.message})
    end
  end
end
