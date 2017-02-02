class CreateDocuments < ActiveRecord::Migration[5.0]
  def change
    create_table :documents do |t|
      t.json :params, null: false
      t.string :status, null: false
      t.string :document_type, null: false
      t.integer :document_number, null: false, unique: true, index: true

      t.timestamps
    end
  end
end
