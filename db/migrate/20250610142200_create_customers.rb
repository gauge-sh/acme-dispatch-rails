class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :name, null: false
      t.string :contact_email
      t.string :phone
      t.string :service_address, null: false

      t.timestamps
    end
  end
end
