class AddReferencedToHeldBalance < ActiveRecord::Migration[5.0]
  def change
    add_reference :held_balances, :document, index: true, foreign_key: true
  end
end
