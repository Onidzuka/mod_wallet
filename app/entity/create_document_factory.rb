class CreateDocumentFactory < BaseDocumentFactory

  def initialize(document)
    self.document = document
  end

  def get_document
    base_document_class(create_document_class).new(document)
  end

  private

  attr_accessor :document

  def create_document_class
    'Create' + document.params['type'].capitalize + 'Document'
  end

end