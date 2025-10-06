class CreateInvoiceLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_line_items do |t|
      t.references :invoice_record, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :kind, null: false
      t.string :description, null: false
      t.decimal :quantity, precision: 12, scale: 6, null: false
      t.integer :unit_cents, null: false
      t.integer :amount_cents, null: false
      t.boolean :weekend, null: false, default: false

      t.timestamps
    end

    add_index :invoice_line_items, [ :invoice_record_id, :position ], unique: true
  end
end
