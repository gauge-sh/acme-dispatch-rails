require "test_helper"

class PartTest < ActiveSupport::TestCase
  def build_part(sku: "CAP-0450", price: 900, cost: 500)
    Part.new(sku: sku, name: "Run capacitor", unit_cost_cents: cost, unit_price_cents: price)
  end

  test "creating a part opens its stock level at zero" do
    part = build_part
    part.save!
    assert_equal 0, part.stock_level.quantity_on_hand
  end

  test "sku must be upper-case alphanumerics and dashes" do
    %w[CAP-0450 IGN4420 A 40-CHARS-EXACTLY-00000000000000000000000].each do |sku|
      assert build_part(sku: sku).valid?, sku
    end
    [ "cap-0450", "CAP 0450", "CAP_0450", "", "x" * 41 ].each do |sku|
      assert_not build_part(sku: sku).valid?, sku.inspect
    end
  end

  test "sku is unique" do
    assert_not build_part(sku: parts(:igniter).sku).valid?
  end

  test "cost and price must be positive" do
    assert_not build_part(cost: 0, price: 900).valid?
    assert_not build_part(cost: 500, price: 0).valid?
    assert_not build_part(cost: -5, price: 900).valid?
  end

  test "price cannot fall below cost, on create or update" do
    part = build_part(cost: 500, price: 499)
    assert_not part.valid?
    assert_includes part.errors[:unit_price_cents], "unit price cannot be below unit cost"

    existing = parts(:igniter)
    existing.unit_price_cents = existing.unit_cost_cents - 1
    assert_not existing.valid?

    existing.unit_price_cents = existing.unit_cost_cents
    assert existing.valid?
  end
end
