require_relative "api_case"

class JobPartsApiTest < ApiCase
  test "recording a part decrements stock in the same transaction" do
    post_api "/jobs/#{jobs(:furnace).id}/parts", { part_id: parts(:igniter).id, quantity: 3 }
    assert_response :created
    assert_equal %w[id job_id part_id quantity unit_price_cents created_at updated_at], body.keys
    assert_equal 1299, body["unit_price_cents"]
    assert_equal 7, stock_levels(:igniter).reload.quantity_on_hand
  end

  test "insufficient stock is a 409 and writes nothing" do
    post_api "/jobs/#{jobs(:furnace).id}/parts", { part_id: parts(:valve).id, quantity: 1 }
    assert_response :conflict
    assert_api_error "insufficient_stock", "not enough stock on hand"
    assert_equal 0, jobs(:furnace).job_parts.count
  end

  test "quantity must be a positive integer" do
    post_api "/jobs/#{jobs(:furnace).id}/parts", { part_id: parts(:igniter).id, quantity: 0 }
    assert_response :bad_request
    assert_api_error "validation_failed", "quantity must be greater than zero"

    post_api "/jobs/#{jobs(:furnace).id}/parts", { part_id: parts(:igniter).id, quantity: "2" }
    assert_response :bad_request

    post_api "/jobs/#{jobs(:furnace).id}/parts", { part_id: parts(:igniter).id }
    assert_response :bad_request
  end

  test "unknown jobs and parts 404" do
    post_api "/jobs/999999/parts", { part_id: parts(:igniter).id, quantity: 1 }
    assert_response :not_found
    assert_api_error "not_found", "job not found"

    post_api "/jobs/#{jobs(:furnace).id}/parts", { part_id: 999999, quantity: 1 }
    assert_response :not_found
    assert_api_error "not_found", "part not found"
  end

  test "terminal jobs take no parts" do
    jobs(:oven).transition_to!("cancelled")
    post_api "/jobs/#{jobs(:oven).id}/parts", { part_id: parts(:igniter).id, quantity: 1 }
    assert_response :bad_request
    assert_api_error "validation_failed", "parts cannot be added to a job that is cancelled"
  end

  test "deleting a job part returns the quantity to stock" do
    post_api "/jobs/#{jobs(:furnace).id}/parts", { part_id: parts(:igniter).id, quantity: 3 }
    record_id = body["id"]

    delete_api "/job-parts/#{record_id}"
    assert_response :no_content
    assert_equal 10, stock_levels(:igniter).reload.quantity_on_hand
  end

  test "an invoiced job's parts cannot be removed" do
    job = jobs(:furnace)
    post_api "/jobs/#{job.id}/parts", { part_id: parts(:igniter).id, quantity: 3 }
    record_id = body["id"]
    complete(job).invoice!

    delete_api "/job-parts/#{record_id}"
    assert_response :bad_request
    assert_api_error "validation_failed", "an invoiced job cannot be changed"
    assert JobPart.exists?(record_id)
  end
end
