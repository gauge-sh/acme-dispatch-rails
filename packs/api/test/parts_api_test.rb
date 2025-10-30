require_relative "api_case"

class PartsApiTest < ApiCase
  test "lists parts" do
    get_api "/parts"
    part = body["items"].find { |p| p["id"] == parts(:igniter).id }
    assert_equal %w[id sku name unit_cost_cents unit_price_cents created_at updated_at], part.keys
    assert_equal "IGN-4420", part["sku"]
  end

  test "q matches sku or name" do
    get_api "/parts", q: "ign"
    assert_equal [ parts(:igniter).id ], body["items"].map { |p| p["id"] }

    get_api "/parts", q: "filter"
    assert_equal [ parts(:filter).id ], body["items"].map { |p| p["id"] }
  end

  test "creating a part opens its stock level at zero" do
    post_api "/parts", { sku: "CAP-0450", name: "Run capacitor", unit_cost_cents: 500, unit_price_cents: 900 }
    assert_response :created

    get_api "/stock-levels", part_id: body["id"]
    level = body["items"].sole
    assert_equal 0, level["quantity_on_hand"]
  end

  test "price below cost is refused with the contract message" do
    post_api "/parts", { sku: "CAP-0450", name: "Run capacitor", unit_cost_cents: 500, unit_price_cents: 499 }
    assert_response :bad_request
    assert_api_error "validation_failed", "unit price cannot be below unit cost"

    patch_api "/parts/#{parts(:igniter).id}", { unit_price_cents: 100 }
    assert_response :bad_request
    assert_api_error "validation_failed", "unit price cannot be below unit cost"
  end

  test "duplicate skus are refused" do
    post_api "/parts", { sku: parts(:igniter).sku, name: "Copy", unit_cost_cents: 1, unit_price_cents: 2 }
    assert_response :bad_request
    assert_equal "has already been taken", body.dig("error", "fields", "sku")
  end

  test "admins delete unused parts" do
    delete_api "/parts/#{parts(:valve).id}", token: @admin_token
    assert_response :no_content
    assert_not StockLevel.exists?(part_id: parts(:valve).id)
  end
end
