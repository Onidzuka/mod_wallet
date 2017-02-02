class CreateFolders < ActiveRecord::Migration[5.0]
  def change
    create_table :folders do |t|

      t.timestamps
    end
  end
end
