require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "defaults to an active dispatcher" do
    user = User.create!(email: "nadia@acme-dispatch.example", name: "Nadia Osei", password: "dispatch-me-1")
    assert_equal "dispatcher", user.role
    assert user.is_active
  end

  test "email is unique, case-insensitively" do
    user = User.new(email: "MARISOL@acme-dispatch.example", name: "Dup", password: "dispatch-me-1")
    assert_not user.valid?
  end

  test "email must contain @" do
    user = User.new(email: "not-an-email", name: "Nadia Osei", password: "dispatch-me-1")
    assert_not user.valid?
  end

  test "name is required" do
    user = User.new(email: "nadia@acme-dispatch.example", name: "  ", password: "dispatch-me-1")
    assert_not user.valid?
  end

  test "role only takes the wire values" do
    user = users(:teddy)
    user.role = "supervisor"
    assert_not user.valid?
  end

  test "an inactive user cannot authenticate" do
    user = users(:teddy)
    assert user.active_for_authentication?

    user.update!(is_active: false)
    assert_not user.active_for_authentication?
  end

  test "passwords are checked against the stored digest" do
    assert users(:marisol).valid_password?("dispatch-me-1")
    assert_not users(:marisol).valid_password?("wrong")
  end
end
