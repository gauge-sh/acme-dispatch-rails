class CreateInvoiceRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_records do |t|
      t.references :job, null: false, foreign_key: true, index: { unique: true }
      t.integer :labor_cents, null: false
      t.integer :parts_cents, null: false
      t.integer :total_cents, null: false

      t.timestamps
    end
  end
end
