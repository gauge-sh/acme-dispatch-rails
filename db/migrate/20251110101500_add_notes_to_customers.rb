class AddNotesToCustomers < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :notes, :text
  end
end
