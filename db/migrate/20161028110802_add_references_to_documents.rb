class AddReferencesToDocuments < ActiveRecord::Migration[5.0]
  def change
    add_column :documents, :amount, :decimal, :precision => 8, :scale => 2
    add_column :documents, :source_account_id, :integer
    add_column :documents, :target_account_id, :integer

    add_index :documents, :source_account_id
    add_index :documents, :target_account_id
  end
end
