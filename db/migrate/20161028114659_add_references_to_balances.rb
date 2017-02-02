class AddReferencesToBalances < ActiveRecord::Migration[5.0]
  def change
    add_reference :balances, :document, index: true, foreign_key: true
  end
end
