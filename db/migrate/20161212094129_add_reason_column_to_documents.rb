class AddReasonColumnToDocuments < ActiveRecord::Migration[5.0]
  def change
    add_column :documents, :reason, :string
  end
end
