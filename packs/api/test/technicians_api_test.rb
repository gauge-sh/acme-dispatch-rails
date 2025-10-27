require_relative "api_case"

class TechniciansApiTest < ApiCase
  test "lists technicians with skill tags as arrays" do
    get_api "/technicians"
    technician = body["items"].find { |t| t["id"] == technicians(:reyes).id }
    assert_equal %w[id name phone skill_tags hourly_cost_cents is_active created_at updated_at], technician.keys
    assert_equal %w[electrical hvac], technician["skill_tags"]
    assert_equal 8000, technician["hourly_cost_cents"]
  end

  test "filters by is_active and by skill" do
    technicians(:fossey).update!(is_active: false)

    get_api "/technicians", is_active: "false"
    assert_equal [ technicians(:fossey).id ], body["items"].map { |t| t["id"] }

    get_api "/technicians", is_active: "true"
    assert_not_includes body["items"].map { |t| t["id"] }, technicians(:fossey).id

    get_api "/technicians", skill: "hvac"
    assert_equal [ technicians(:reyes).id ], body["items"].map { |t| t["id"] }

    get_api "/technicians", skill: "roofing"
    assert_empty body["items"]

    get_api "/technicians", is_active: "yes"
    assert_response :bad_request
  end

  test "creates with normalized tags" do
    post_api "/technicians", { name: "Ana Sosa", hourly_cost_cents: 7200, skill_tags: [ "HVAC", "hvac", " Electrical" ] }
    assert_response :created
    assert_equal %w[electrical hvac], body["skill_tags"]
    assert body["is_active"]
  end

  test "rejects a non-positive rate" do
    post_api "/technicians", { name: "Ana Sosa", hourly_cost_cents: 0 }
    assert_response :bad_request
    assert_equal "validation_failed", body.dig("error", "code")
  end

  test "updates and clears optional phone" do
    patch_api "/technicians/#{technicians(:reyes).id}", { phone: nil }
    assert_response :success
    assert_nil body["phone"]
  end

  test "deactivating an assigned technician is allowed" do
    schedule(job: jobs(:furnace), technician: technicians(:reyes), from: [ 9 ], to: [ 10 ])
    patch_api "/technicians/#{technicians(:reyes).id}", { is_active: false }
    assert_response :success
    assert_not body["is_active"]
  end

  test "admins cannot delete a technician with appointments" do
    schedule(job: jobs(:furnace), technician: technicians(:reyes), from: [ 9 ], to: [ 10 ])
    delete_api "/technicians/#{technicians(:reyes).id}", token: @admin_token
    assert_response :bad_request
    assert_api_error "validation_failed", "technician has appointments and cannot be deleted"
  end

  test "an inactive technician cannot be booked" do
    technicians(:okada).update!(is_active: false)
    post_api "/appointments", {
      job_id: jobs(:furnace).id,
      technician_id: technicians(:okada).id,
      scheduled_start: "2025-03-12T09:00:00Z",
      scheduled_end: "2025-03-12T10:00:00Z"
    }
    assert_response :bad_request
    assert_api_error "validation_failed", "technician is not active"
  end
end
