class CreateHeldBalances < ActiveRecord::Migration[5.0]
  def change
    create_table :held_balances do |t|
      t.decimal :amount, :precision => 8, :scale => 2, :null => false
      t.references :account, foreign_key: true

      t.timestamps
    end
  end
end
