require_relative "web_case"

class CustomersTest < WebCase
  setup { sign_in_dispatcher }

  test "lists and searches customers" do
    get customers_path
    assert_response :success
    assert_select "td a", text: "Meridian Property Group"

    get customers_path, params: { q: "harbor" }
    assert_select "td a", text: "Harbor Lane Bakery"
    assert_select "td a", text: "Meridian Property Group", count: 0

    get customers_path, params: { q: "zzz" }
    assert_select ".empty", text: /No customers match/
  end

  test "creates a customer through the form" do
    get new_customer_path
    assert_response :success

    assert_difference "Customer.count" do
      post customers_path, params: { customer: { name: "Bluebird Cafe", service_address: "77 Main St" } }
    end
    follow_redirect!
    assert_select "h1", "Bluebird Cafe"
  end

  test "re-renders the form with errors" do
    post customers_path, params: { customer: { name: "", service_address: "77 Main St" } }
    assert_response :unprocessable_entity
    assert_select ".errors li", text: /Name/
  end

  test "edits a customer" do
    patch customer_path(customers(:quinn)), params: { customer: { phone: "555-0100" } }
    follow_redirect!
    assert_select "dd", text: "555-0100"
  end

  test "deleting a customer with jobs shows the domain message" do
    delete customer_path(customers(:meridian))
    assert_redirected_to customer_path(customers(:meridian))
    follow_redirect!
    assert_select ".flash-alert", text: /has jobs and cannot be deleted/
    assert Customer.exists?(customers(:meridian).id)
  end

  test "deletes a customer without jobs" do
    customer = Customer.create!(name: "One Off", service_address: "9 Side St")
    assert_difference "Customer.count", -1 do
      delete customer_path(customer)
    end
  end
end
