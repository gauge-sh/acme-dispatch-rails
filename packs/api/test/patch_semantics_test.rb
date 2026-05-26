require_relative "api_case"

# PATCH means: absent keys untouched, explicit null clears, values replace.
# One resource per nullable field family, so a regression names its owner.
class PatchSemanticsTest < ApiCase
  test "customers" do
    customer = customers(:meridian)

    patch_api "/customers/#{customer.id}", { name: "Meridian PG" }
    assert_equal "Meridian PG", body["name"]
    assert_equal "facilities@meridianpg.example", body["contact_email"]

    patch_api "/customers/#{customer.id}", { contact_email: nil, phone: nil, notes: nil }
    assert_nil body["contact_email"]
    assert_nil body["phone"]
    assert_equal "Meridian PG", body["name"]

    patch_api "/customers/#{customer.id}", { contact_email: "ops@meridianpg.example" }
    assert_equal "ops@meridianpg.example", body["contact_email"]
  end

  test "technicians" do
    technician = technicians(:reyes)

    patch_api "/technicians/#{technician.id}", { hourly_cost_cents: 8500 }
    assert_equal 8500, body["hourly_cost_cents"]
    assert_equal "555-882-4413", body["phone"]
    assert_equal %w[electrical hvac], body["skill_tags"]

    patch_api "/technicians/#{technician.id}", { skill_tags: [] }
    assert_equal [], body["skill_tags"]
    assert_equal 8500, body["hourly_cost_cents"]
  end

  test "parts keep both prices unless told otherwise" do
    part = parts(:igniter)

    patch_api "/parts/#{part.id}", { name: "Hot surface igniter, universal" }
    assert_equal 780, body["unit_cost_cents"]
    assert_equal 1299, body["unit_price_cents"]

    patch_api "/parts/#{part.id}", { unit_price_cents: 1399 }
    assert_equal 1399, body["unit_price_cents"]
    assert_equal 780, body["unit_cost_cents"]
  end

  test "jobs" do
    job = jobs(:furnace)

    patch_api "/jobs/#{job.id}", { description: nil }
    assert_nil body["description"]
    assert_equal "Furnace not igniting", body["title"]

    patch_api "/jobs/#{job.id}", { priority: "low" }
    assert_equal "low", body["priority"]
    assert_nil body["description"]
  end

  test "a patch that validates poorly changes nothing" do
    customer = customers(:meridian)
    patch_api "/customers/#{customer.id}", { name: "", notes: "should not stick" }
    assert_response :bad_request
    assert_equal "Meridian Property Group", customer.reload.name
    assert_nil customer.notes
  end

  test "patching an unknown id is a 404, not a create" do
    patch_api "/customers/999999", { name: "Ghost" }
    assert_response :not_found
    assert_nil Customer.find_by(name: "Ghost")
  end
end
