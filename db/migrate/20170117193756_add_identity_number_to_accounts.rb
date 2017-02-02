class AddIdentityNumberToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :identity_number, :string, null: false, index: true, unique: true
  end
end
