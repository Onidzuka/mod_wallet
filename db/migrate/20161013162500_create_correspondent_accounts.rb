class CreateCorrespondentAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :correspondent_accounts do |t|
      t.decimal :amount, :precision => 8, :scale => 2, :null => false

      t.timestamps
    end
  end
end
