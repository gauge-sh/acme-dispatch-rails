class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, index: { unique: true }
      t.string :encrypted_password, null: false
      t.string :name, null: false
      t.string :role, null: false, default: "dispatcher"
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end
  end
end
