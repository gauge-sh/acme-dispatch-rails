class AddIsActiveToTechnicians < ActiveRecord::Migration[8.1]
  def change
    add_column :technicians, :is_active, :boolean, null: false, default: true
  end
end
