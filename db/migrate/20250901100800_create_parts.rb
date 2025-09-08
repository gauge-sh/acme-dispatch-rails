class CreateParts < ActiveRecord::Migration[8.1]
  def change
    create_table :parts do |t|
      t.string :sku, null: false, index: { unique: true }
      t.string :name, null: false
      t.integer :unit_cost_cents, null: false
      t.integer :unit_price_cents, null: false

      t.timestamps
    end
  end
end
