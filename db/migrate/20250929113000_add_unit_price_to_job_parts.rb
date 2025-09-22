class AddUnitPriceToJobParts < ActiveRecord::Migration[8.1]
  def up
    add_column :job_parts, :unit_price_cents, :integer

    # Existing rows get today's catalog price; from here on the price is
    # captured at the moment the part is used, so later catalog changes do
    # not restate old bills.
    execute <<~SQL
      UPDATE job_parts
      SET unit_price_cents = (SELECT unit_price_cents FROM parts WHERE parts.id = job_parts.part_id)
    SQL

    change_column_null :job_parts, :unit_price_cents, false
  end

  def down
    remove_column :job_parts, :unit_price_cents
  end
end
