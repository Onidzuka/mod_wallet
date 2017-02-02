class BaseDocumentFactory

  def base_document_class(const_as_string)
    Object.const_get(const_as_string)
  end

end