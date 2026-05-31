require_relative "api_case"

class InvoiceRecordsApiTest < ApiCase
  # The same setup as conformance case 4: 1.5h at 8000c/h on a weekday plus
  # 3 x 1299c parts, urgent priority.
  def build_case_four_job
    job = jobs(:furnace)
    schedule(job: job, technician: technicians(:reyes), from: [ 13 ], to: [ 14, 30 ])
    JobPart.create!(job: job, part: parts(:igniter), quantity: 3)
    job.transition_to!("scheduled").transition_to!("in_progress").transition_to!("completed")
    job
  end

  test "invoicing a completed job returns the record and moves the job" do
    job = build_case_four_job
    post_api "/jobs/#{job.id}/invoice"
    assert_response :created

    assert_equal %w[id job_id labor_cents parts_cents total_cents line_items created_at updated_at], body.keys
    assert_equal 19200, body["labor_cents"]
    assert_equal 3897, body["parts_cents"]
    assert_equal 25407, body["total_cents"]
    assert_equal "invoiced", job.reload.status

    labor, part = body["line_items"]
    assert_equal %w[kind description quantity unit_cents amount_cents weekend], labor.keys
    assert_equal "labor", labor["kind"]
    assert_equal "Dana Reyes — 1.5h on 2025-03-12", labor["description"]
    assert_equal 1.5, labor["quantity"]
    assert_equal 8000, labor["unit_cents"]
    assert_equal 19200, labor["amount_cents"]
    assert_equal false, labor["weekend"]

    assert_equal "part", part["kind"]
    assert_equal "IGN-4420 — Hot surface igniter", part["description"]
    assert_equal 3, part["quantity"]
    assert_equal false, part["weekend"]
  end

  test "a non-terminating duration serializes as the shortest round-trip double" do
    job = jobs(:oven)
    schedule(job: job, technician: technicians(:reyes), from: [ 9 ], to: [ 9, 20 ])
    job.transition_to!("scheduled").transition_to!("in_progress").transition_to!("completed")

    post_api "/jobs/#{job.id}/invoice"
    line = body["line_items"].sole
    assert_equal 1.0 / 3, line["quantity"]
    assert_includes response.body, "\"quantity\":0.3333333333333333"
    # The amount comes from the exact third of an hour, not the rendering.
    assert_equal 4267, line["amount_cents"]
    assert_includes line["description"], "0.33h"
  end

  test "whole-hour labor serializes quantity as a bare integer" do
    job = complete(jobs(:oven))
    post_api "/jobs/#{job.id}/invoice"
    quantity = body["line_items"].first["quantity"]
    assert_equal 1, quantity
    assert_instance_of Integer, quantity
  end

  test "a weekend appointment is surcharged per line" do
    job = jobs(:oven)
    schedule(job: job, technician: technicians(:okada), from: [ 9 ], to: [ 11 ], day: [ 2025, 3, 15 ])
    job.transition_to!("scheduled").transition_to!("in_progress").transition_to!("completed")

    post_api "/jobs/#{job.id}/invoice"
    line = body["line_items"].sole
    assert line["weekend"]
    assert_equal 18400, line["amount_cents"]
    assert_equal 18400, body["total_cents"]
  end

  test "only completed jobs invoice" do
    post_api "/jobs/#{jobs(:oven).id}/invoice"
    assert_response :conflict
    assert_api_error "invalid_transition", "only a completed job can be invoiced"
  end

  test "re-invoicing is a validation failure, not a transition error" do
    job = build_case_four_job
    post_api "/jobs/#{job.id}/invoice"
    assert_response :created

    post_api "/jobs/#{job.id}/invoice"
    assert_response :bad_request
    assert_api_error "validation_failed", "job is already invoiced"
  end

  test "records list with line items and filter by job and customer" do
    job = build_case_four_job
    post_api "/jobs/#{job.id}/invoice"
    record_id = body["id"]

    get_api "/invoice-records"
    item = body["items"].sole
    assert_equal record_id, item["id"]
    assert_equal 2, item["line_items"].size

    get_api "/invoice-records", job_id: job.id
    assert_equal [ record_id ], body["items"].map { |r| r["id"] }

    get_api "/invoice-records", customer_id: customers(:meridian).id
    assert_equal [ record_id ], body["items"].map { |r| r["id"] }

    get_api "/invoice-records", customer_id: customers(:quinn).id
    assert_empty body["items"]

    get_api "/invoice-records/#{record_id}"
    assert_equal 25407, body["total_cents"]
  end

  test "record lists paginate like everything else" do
    job = build_case_four_job
    post_api "/jobs/#{job.id}/invoice"

    get_api "/invoice-records", per_page: 1
    assert_equal %w[items page per_page total], body.keys
    assert_equal 1, body["total"]

    get_api "/invoice-records", page: 2, per_page: 1
    assert_empty body["items"]
    assert_equal 1, body["total"]
  end

  test "line items keep their order on every read" do
    job = build_case_four_job
    post_api "/jobs/#{job.id}/invoice"
    record_id = body["id"]

    3.times do
      get_api "/invoice-records/#{record_id}"
      assert_equal %w[labor part], body["line_items"].map { |line| line["kind"] }
    end
  end

  test "records are immutable over the wire" do
    job = build_case_four_job
    post_api "/jobs/#{job.id}/invoice"
    record_id = body["id"]

    patch "/api/v1/invoice-records/#{record_id}", params: "{}",
      headers: { "Authorization" => "Bearer #{@dispatcher_token}", "Content-Type" => "application/json" }
    assert_response :not_found

    delete "/api/v1/invoice-records/#{record_id}",
      headers: { "Authorization" => "Bearer #{@dispatcher_token}" }
    assert_response :not_found
  end
end
