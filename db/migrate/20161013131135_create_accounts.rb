class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.boolean :closed, default: false, null: false

      t.timestamps
    end
  end
end