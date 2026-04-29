require_relative "api_case"

# Key order is part of the wire contract, not an implementation accident.
# These tests fail if a serializer reorders or drops a key.
class WireShapesTest < ApiCase
  test "technician keys" do
    get_api "/technicians/#{technicians(:reyes).id}"
    assert_equal %w[id name phone skill_tags hourly_cost_cents is_active created_at updated_at], body.keys
  end

  test "customer keys" do
    get_api "/customers/#{customers(:meridian).id}"
    assert_equal %w[id name contact_email phone service_address notes created_at updated_at], body.keys
  end

  test "user keys" do
    get_api "/users/#{users(:teddy).id}", token: @admin_token
    assert_equal %w[id email name role is_active created_at updated_at], body.keys
  end

  test "stock level keys, including the nested part" do
    get_api "/stock-levels", part_id: parts(:igniter).id
    level = body["items"].sole
    assert_equal %w[id part_id quantity_on_hand part created_at updated_at], level.keys
    assert_equal %w[id sku name unit_cost_cents unit_price_cents created_at updated_at], level["part"].keys
  end

  test "appointment keys" do
    appointment = schedule(job: jobs(:furnace), technician: technicians(:reyes), from: [ 9 ], to: [ 10 ])
    get_api "/appointments/#{appointment.id}"
    assert_equal %w[id job_id technician_id scheduled_start scheduled_end completion_notes created_at updated_at],
      body.keys
  end

  test "nested appointments order by start then id, job parts by id" do
    late = schedule(job: jobs(:furnace), technician: technicians(:reyes), from: [ 14 ], to: [ 15 ])
    early = schedule(job: jobs(:furnace), technician: technicians(:okada), from: [ 8 ], to: [ 9 ])
    first_part = JobPart.create!(job: jobs(:furnace), part: parts(:filter), quantity: 1)
    second_part = JobPart.create!(job: jobs(:furnace), part: parts(:igniter), quantity: 1)

    get_api "/jobs/#{jobs(:furnace).id}"
    assert_equal [ early.id, late.id ], body["appointments"].map { |a| a["id"] }
    assert_equal [ first_part.id, second_part.id ], body["job_parts"].map { |jp| jp["id"] }
  end

  test "timestamps are utc with a z suffix everywhere" do
    get_api "/customers/#{customers(:meridian).id}"
    assert_match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/, body["created_at"])
    assert_match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/, body["updated_at"])
  end

  test "patching an appointment with explicit nulls clears the notes" do
    appointment = schedule(job: jobs(:furnace), technician: technicians(:reyes), from: [ 9 ], to: [ 10 ])
    appointment.update!(completion_notes: "swap the filter")

    patch_api "/appointments/#{appointment.id}", { completion_notes: nil }
    assert_response :success
    assert_nil body["completion_notes"]
    assert_nil appointment.reload.completion_notes
  end

  test "patching without a key leaves the value alone" do
    appointment = schedule(job: jobs(:furnace), technician: technicians(:reyes), from: [ 9 ], to: [ 10 ])
    appointment.update!(completion_notes: "swap the filter")

    patch_api "/appointments/#{appointment.id}", { scheduled_end: "2025-03-12T10:30:00Z" }
    assert_equal "swap the filter", body["completion_notes"]
  end

  test "a malformed json body is a validation failure" do
    post "/api/v1/customers", params: "{not json",
      headers: { "Authorization" => "Bearer #{@dispatcher_token}", "Content-Type" => "application/json" }
    assert_response :bad_request
    assert_api_error "validation_failed", "request body is not valid json"
  end
end
