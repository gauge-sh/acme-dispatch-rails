require_relative "web_case"

class ScheduleTest < WebCase
  setup do
    sign_in_dispatcher
    @today = Time.zone.today
    @visit = Appointment.create!(
      job: jobs(:furnace), technician: technicians(:reyes),
      scheduled_start: @today.to_time(:utc).change(hour: 9),
      scheduled_end: @today.to_time(:utc).change(hour: 11)
    )
    Appointment.create!(
      job: jobs(:oven), technician: technicians(:okada),
      scheduled_start: (@today + 1).to_time(:utc).change(hour: 9),
      scheduled_end: (@today + 1).to_time(:utc).change(hour: 10)
    )
  end

  test "shows one day at a time" do
    get schedule_path
    assert_select "td a", text: "Furnace not igniting"
    assert_select "td a", text: "Deck oven runs cold", count: 0

    get schedule_path(day: (@today + 1).iso8601)
    assert_select "td a", text: "Deck oven runs cold"
  end

  test "filters by technician" do
    Appointment.create!(
      job: jobs(:fence_light), technician: technicians(:okada),
      scheduled_start: @today.to_time(:utc).change(hour: 13),
      scheduled_end: @today.to_time(:utc).change(hour: 14)
    )

    get schedule_path(technician_id: technicians(:reyes).id)
    assert_select "td a", text: "Furnace not igniting"
    assert_select "td a", text: "Path light flickering", count: 0
  end

  test "an empty day says so" do
    get schedule_path(day: (@today - 30).iso8601)
    assert_select ".empty", text: "No visits on this day."
  end

  test "a junk day parameter falls back to today" do
    get schedule_path(day: "not-a-day")
    assert_response :success
    assert_select "td a", text: "Furnace not igniting"
  end
end
