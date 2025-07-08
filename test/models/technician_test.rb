require "test_helper"

class TechnicianTest < ActiveSupport::TestCase
  test "valid with a name and a positive rate" do
    technician = Technician.new(name: "Sam Ortiz", hourly_cost_cents: 6500)
    assert technician.valid?
    assert_equal [], technician.skill_tags
  end

  test "rate must be a positive integer" do
    technician = technicians(:reyes)
    [ 0, -100, 12.5 ].each do |rate|
      technician.hourly_cost_cents = rate
      assert_not technician.valid?, rate.inspect
    end
  end

  test "skill tags are lower-cased, deduplicated and sorted" do
    technician = Technician.create!(
      name: "Sam Ortiz",
      hourly_cost_cents: 6500,
      skill_tags: [ "HVAC", "electrical", "hvac", "  Plumbing " ]
    )
    assert_equal %w[electrical hvac plumbing], technician.skill_tags
  end

  test "blank tags are dropped" do
    technician = Technician.new(name: "Sam Ortiz", hourly_cost_cents: 6500, skill_tags: [ "", "  ", "hvac" ])
    assert technician.valid?
    assert_equal %w[hvac], technician.skill_tags
  end

  test "a tag cannot exceed 40 characters" do
    technician = Technician.new(name: "Sam Ortiz", hourly_cost_cents: 6500, skill_tags: [ "x" * 41 ])
    assert_not technician.valid?
  end

  test "name is trimmed and bounded" do
    technician = Technician.new(name: "  Sam Ortiz ", hourly_cost_cents: 6500)
    technician.valid?
    assert_equal "Sam Ortiz", technician.name

    assert_not Technician.new(name: "x" * 121, hourly_cost_cents: 6500).valid?
    assert_not Technician.new(name: "", hourly_cost_cents: 6500).valid?
  end
end
