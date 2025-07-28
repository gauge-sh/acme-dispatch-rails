class CreateJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :jobs do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :priority, null: false, default: "normal"
      t.string :status, null: false, default: "requested"

      t.timestamps
    end
  end
end
