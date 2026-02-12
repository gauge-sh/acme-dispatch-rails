class AddJobFilterIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :jobs, :status
    add_index :jobs, :priority
  end
end
