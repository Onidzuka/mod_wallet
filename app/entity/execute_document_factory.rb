class ExecuteDocumentFactory < BaseDocumentFactory
  def get_document(document_number)
    document = Document.find_by_document_number(document_number)
    if document&.created?
      class_as_string = execute_document_class(document)
      base_document_class(class_as_string).new(document)
    elsif document
      raise Exceptions::InvalidRequest
    else
      raise Exceptions::DocumentNotFound
    end
  end

  private

  def status_created?(document)
    document.status == 'created'
  end

  def execute_document_class(document)
    'Execute' + document.params['type'].capitalize + 'Document'
  end
end
