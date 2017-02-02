class AddCountryCodeToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :country_code, :string, null: false
  end
end
