require_relative "web_case"

class TechniciansTest < WebCase
  setup { sign_in_dispatcher }

  test "lists active technicians and filters by skill" do
    technicians(:fossey).update!(is_active: false)

    get technicians_path
    assert_select "td a", text: "Dana Reyes"
    assert_select "td a", text: "Marta Fossey", count: 0

    get technicians_path, params: { show: "inactive" }
    assert_select "td a", text: "Marta Fossey"

    get technicians_path, params: { skill: "plumbing" }
    assert_select "td a", text: "Ben Okada"
    assert_select "td a", text: "Dana Reyes", count: 0
  end

  test "creates a technician with comma-separated skills" do
    post technicians_path, params: { technician: { name: "Ana Sosa", hourly_cost_cents: 7200, skill_tags: "HVAC, electrical" } }
    technician = Technician.find_by!(name: "Ana Sosa")
    assert_equal %w[electrical hvac], technician.skill_tags
    assert_redirected_to technician_path(technician)
  end

  test "rejects a zero rate with inline errors" do
    post technicians_path, params: { technician: { name: "Ana Sosa", hourly_cost_cents: 0 } }
    assert_response :unprocessable_entity
    assert_select ".errors li"
  end

  test "the schedule view groups a week by day" do
    monday = Time.zone.today.beginning_of_week
    Appointment.create!(
      job: jobs(:furnace), technician: technicians(:reyes),
      scheduled_start: monday.to_time(:utc).change(hour: 9),
      scheduled_end: monday.to_time(:utc).change(hour: 11)
    )

    get schedule_technician_path(technicians(:reyes), week: monday.iso8601)
    assert_response :success
    assert_select "h2", text: monday.strftime("%A, %b %-d")
    assert_select "td a", text: "Furnace not igniting"

    get schedule_technician_path(technicians(:reyes), week: (monday - 7).iso8601)
    assert_select ".empty", text: "No appointments this week."
  end

  test "only admins can delete technicians" do
    delete technician_path(technicians(:fossey))
    assert_redirected_to root_path
    assert Technician.exists?(technicians(:fossey).id)

    sign_in_admin
    delete technician_path(technicians(:fossey))
    assert_redirected_to technicians_path
    assert_not Technician.exists?(technicians(:fossey).id)
  end

  test "deleting a booked technician surfaces the guard" do
    Appointment.create!(
      job: jobs(:furnace), technician: technicians(:reyes),
      scheduled_start: Time.utc(2025, 9, 10, 9), scheduled_end: Time.utc(2025, 9, 10, 10)
    )
    sign_in_admin
    delete technician_path(technicians(:reyes))
    follow_redirect!
    assert_select ".flash-alert", text: /has appointments/
  end
end
