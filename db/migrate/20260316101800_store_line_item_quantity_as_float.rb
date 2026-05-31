class StoreLineItemQuantityAsFloat < ActiveRecord::Migration[8.1]
  # The wire defines quantity as the IEEE-754 double of the exact duration
  # (shortest round-trip form). A scale-6 decimal truncated non-terminating
  # durations to 0.333333; storing the double itself makes the column and the
  # wire agree by construction. Amounts never came from this column.
  def up
    change_column :invoice_line_items, :quantity, :float, null: false
  end

  def down
    change_column :invoice_line_items, :quantity, :decimal, precision: 12, scale: 6, null: false
  end
end
