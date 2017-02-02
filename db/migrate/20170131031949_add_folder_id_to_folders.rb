class AddFolderIdToFolders < ActiveRecord::Migration[5.0]
  def change
    add_column :folders, :folder_id, :integer, null: false, unique: true, index: true
  end
end
