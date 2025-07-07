class CreateTechnicians < ActiveRecord::Migration[8.1]
  def change
    create_table :technicians do |t|
      t.string :name, null: false
      t.string :phone
      t.json :skill_tags, null: false, default: []
      t.integer :hourly_cost_cents, null: false

      t.timestamps
    end
  end
end
