class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.references :job, null: false, foreign_key: true
      t.references :technician, null: false, foreign_key: true
      t.datetime :scheduled_start, null: false
      t.datetime :scheduled_end, null: false
      t.text :completion_notes

      t.timestamps
    end

    add_index :appointments, [ :technician_id, :scheduled_start ]
  end
end
