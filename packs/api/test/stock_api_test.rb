require_relative "api_case"

class StockApiTest < ApiCase
  test "lists stock with the part nested, ordered by part id" do
    get_api "/stock-levels"
    level = body["items"].first
    assert_equal %w[id part_id quantity_on_hand part created_at updated_at], level.keys
    assert_equal level["part_id"], level.dig("part", "id")
    assert_equal body["items"].map { |l| l["part_id"] }.sort, body["items"].map { |l| l["part_id"] }
  end

  test "filters by part" do
    get_api "/stock-levels", part_id: parts(:filter).id
    assert_equal [ 24 ], body["items"].map { |l| l["quantity_on_hand"] }
  end

  test "adjusts stock up and down" do
    post_api "/stock-levels/#{parts(:igniter).id}/adjust", { delta: 5 }
    assert_response :success
    assert_equal 15, body["quantity_on_hand"]

    post_api "/stock-levels/#{parts(:igniter).id}/adjust", { delta: -15 }
    assert_equal 0, body["quantity_on_hand"]
  end

  test "an adjustment below zero is a 409 and writes nothing" do
    post_api "/stock-levels/#{parts(:igniter).id}/adjust", { delta: -11 }
    assert_response :conflict
    assert_api_error "insufficient_stock", "not enough stock on hand"
    assert_equal 10, stock_levels(:igniter).reload.quantity_on_hand
  end

  test "a zero delta is refused" do
    post_api "/stock-levels/#{parts(:igniter).id}/adjust", { delta: 0 }
    assert_response :bad_request
    assert_api_error "validation_failed", "delta must not be zero"
  end

  test "a non-integer delta is refused" do
    [ 1.5, "3", nil ].each do |delta|
      post_api "/stock-levels/#{parts(:igniter).id}/adjust", { delta: delta }
      assert_response :bad_request, delta.inspect
    end
  end

  test "adjusting an unknown part 404s" do
    post_api "/stock-levels/999999/adjust", { delta: 1 }
    assert_response :not_found
    assert_api_error "not_found", "stock level not found"
  end
end
