class CreateBlockedOperations < ActiveRecord::Migration[5.0]
  def change
    create_table :blocked_operations do |t|
      t.string :operation, null: false
      t.references :account, foreign_key: true, index: true, null: false

      t.timestamps
    end
  end
end
