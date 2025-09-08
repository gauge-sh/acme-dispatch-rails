class CreateStockLevels < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_levels do |t|
      t.references :part, null: false, foreign_key: true, index: { unique: true }
      t.integer :quantity_on_hand, null: false, default: 0

      t.timestamps
    end
  end
end
