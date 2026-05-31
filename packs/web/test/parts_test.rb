require_relative "web_case"

class PartsTest < WebCase
  setup { sign_in_dispatcher }

  test "lists parts with stock counts" do
    get parts_path
    assert_select "td.mono a", text: "IGN-4420"
    assert_select "td.amount", text: "10"

    get parts_path, params: { q: "filter" }
    assert_select "td.mono a", text: "FLT-2001"
    assert_select "td.mono a", text: "IGN-4420", count: 0
  end

  test "creates a part and shows zero stock" do
    post parts_path, params: { part: { sku: "CAP-0450", name: "Run capacitor", unit_cost_cents: 500, unit_price_cents: 900 } }
    part = Part.find_by!(sku: "CAP-0450")
    follow_redirect!
    assert_select "strong", text: "0"
    assert_equal 0, part.stock_level.quantity_on_hand
  end

  test "price below cost re-renders with the contract message" do
    post parts_path, params: { part: { sku: "CAP-0450", name: "Run capacitor", unit_cost_cents: 500, unit_price_cents: 400 } }
    assert_response :unprocessable_entity
    assert_select ".errors li", text: "unit price cannot be below unit cost"
  end

  test "adjusts stock from the part page" do
    post adjust_stock_part_path(parts(:igniter)), params: { delta: 5 }
    assert_equal 15, stock_levels(:igniter).reload.quantity_on_hand

    post adjust_stock_part_path(parts(:igniter)), params: { delta: -20 }
    follow_redirect!
    assert_select ".flash-alert", text: /Not enough stock/
    assert_equal 15, stock_levels(:igniter).reload.quantity_on_hand

    post adjust_stock_part_path(parts(:igniter)), params: { delta: 0 }
    follow_redirect!
    assert_select ".flash-alert", text: /Delta must not be zero/
  end

  test "the part page shows the movement history" do
    post adjust_stock_part_path(parts(:igniter)), params: { delta: 5 }
    JobPart.create!(job: jobs(:furnace), part: parts(:igniter), quantity: 2)

    get part_path(parts(:igniter))
    assert_select ".card", text: /Stock history/
    assert_select "td", text: "manual adjustment"
    assert_select "td", text: "used on job ##{jobs(:furnace).id}"
    assert_select "td", text: "Teddy Marsh"
    assert_select "td", text: "system"
  end

  test "only admins delete parts, and used parts refuse" do
    delete part_path(parts(:valve))
    assert_redirected_to root_path
    assert Part.exists?(parts(:valve).id)

    sign_in_admin
    JobPart.create!(job: jobs(:furnace), part: parts(:igniter), quantity: 1)
    delete part_path(parts(:igniter))
    follow_redirect!
    assert_select ".flash-alert", text: /has been used on jobs/

    delete part_path(parts(:valve))
    assert_redirected_to parts_path
    assert_not Part.exists?(parts(:valve).id)
  end
end
