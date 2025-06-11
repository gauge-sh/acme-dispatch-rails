require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  test "valid with the required fields" do
    customer = Customer.new(name: "Rivera HVAC", service_address: "12 Bay St")
    assert customer.valid?
  end

  test "name and address are trimmed and required" do
    customer = Customer.new(name: "  Rivera HVAC  ", service_address: " 12 Bay St ")
    customer.valid?
    assert_equal "Rivera HVAC", customer.name
    assert_equal "12 Bay St", customer.service_address

    assert_not Customer.new(name: "   ", service_address: "12 Bay St").valid?
    assert_not Customer.new(name: "Rivera", service_address: "").valid?
    assert_not Customer.new(name: "a" * 161, service_address: "12 Bay St").valid?
    assert_not Customer.new(name: "Rivera", service_address: "a" * 241).valid?
  end

  test "contact email must contain @ when present" do
    customer = customers(:quinn)
    customer.contact_email = "not-an-email"
    assert_not customer.valid?

    customer.contact_email = "rosa@quinn.example"
    assert customer.valid?

    customer.contact_email = nil
    assert customer.valid?
  end

  test "blank optional fields store as null" do
    customer = Customer.create!(name: "Rivera HVAC", service_address: "12 Bay St", contact_email: "", phone: " ")
    assert_nil customer.contact_email
    assert_nil customer.phone
  end

  test "phone length is bounded when present" do
    customer = customers(:quinn)
    customer.phone = "123456"
    assert_not customer.valid?

    customer.phone = "1" * 33
    assert_not customer.valid?

    customer.phone = "555-0100"
    assert customer.valid?
  end
end
