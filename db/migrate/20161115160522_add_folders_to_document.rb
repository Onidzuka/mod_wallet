class AddFoldersToDocument < ActiveRecord::Migration[5.0]
  def change
    add_reference :documents, :folder, foreign_key: true
  end
end
