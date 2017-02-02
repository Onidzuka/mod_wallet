class CancelDocument
  include Interactor

  def call
    begin
      documents = Folder.find_by_folder_id!(context.folder_id).documents
      documents.each do |document|
        if document.created?
          cancel(document)
        else
          raise Exceptions::InvalidRequest
        end  
      end
      
    rescue StandardError => e
      context.fail!(message: {errors: e.message})
    end
  end

  private

  def destroy_held_balance(document)
    document.held_balance.destroy if document.has_held_amount?
  end

  def cancel(document)
    Document.transaction do
      document.tap do |doc|
        destroy_held_balance(doc)
        doc.status = 'canceled'
        doc.save!
      end
    end
  end
end
