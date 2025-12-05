class CreateStockAdjustments < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_adjustments do |t|
      t.references :part, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :delta, null: false
      t.integer :quantity_after, null: false
      t.string :note

      t.timestamps
    end
  end
end
