class CreateJobParts < ActiveRecord::Migration[8.1]
  def change
    create_table :job_parts do |t|
      t.references :job, null: false, foreign_key: true
      t.references :part, null: false, foreign_key: true
      t.integer :quantity, null: false

      t.timestamps
    end
  end
end
