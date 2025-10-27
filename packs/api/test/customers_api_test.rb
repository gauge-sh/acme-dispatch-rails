require_relative "api_case"

class CustomersApiTest < ApiCase
  test "lists customers with the full wire shape" do
    get_api "/customers"
    customer = body["items"].find { |c| c["id"] == customers(:meridian).id }
    assert_equal %w[id name contact_email phone service_address notes created_at updated_at], customer.keys
    assert_equal "Meridian Property Group", customer["name"]
    assert_match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/, customer["created_at"])
  end

  test "q matches name or address, case-insensitively" do
    get_api "/customers", q: "meridian"
    assert_equal [ customers(:meridian).id ], body["items"].map { |c| c["id"] }

    get_api "/customers", q: "ALDER"
    assert_equal [ customers(:quinn).id ], body["items"].map { |c| c["id"] }

    get_api "/customers", q: "no-such-customer"
    assert_empty body["items"]
    assert_equal 0, body["total"]
  end

  test "creates a customer" do
    post_api "/customers", { name: "Bluebird Cafe", service_address: "77 Main St", contact_email: "hello@bluebird.example" }
    assert_response :created
    assert_equal "Bluebird Cafe", body["name"]
    assert_nil body["phone"]
    assert Customer.exists?(body["id"])
  end

  test "creation validates" do
    post_api "/customers", { name: "", service_address: "77 Main St" }
    assert_response :bad_request
    assert_equal "validation_failed", body.dig("error", "code")
    assert_equal "name can't be blank", body.dig("error", "message")
    assert_equal "can't be blank", body.dig("error", "fields", "name")
  end

  test "shows and 404s" do
    get_api "/customers/#{customers(:quinn).id}"
    assert_response :success
    assert_equal "Rosa Quinn", body["name"]

    get_api "/customers/999999"
    assert_response :not_found
    assert_api_error "not_found", "customer not found"
  end

  test "patch is partial and explicit null clears" do
    customer = customers(:meridian)
    patch_api "/customers/#{customer.id}", { phone: nil }
    assert_response :success
    assert_nil body["phone"]
    assert_equal "Meridian Property Group", customer.reload.name

    patch_api "/customers/#{customer.id}", { notes: "gate code 4411" }
    assert_equal "gate code 4411", customer.reload.notes
    assert_not_nil customer.contact_email
  end

  test "delete returns no content" do
    customer = Customer.create!(name: "Fleeting", service_address: "1 Short St")
    delete_api "/customers/#{customer.id}"
    assert_response :no_content
    assert_empty response.body
    assert_not Customer.exists?(customer.id)
  end

  test "a customer with jobs cannot be deleted" do
    delete_api "/customers/#{customers(:meridian).id}"
    assert_response :bad_request
    assert_api_error "validation_failed", "customer has jobs and cannot be deleted"
    assert Customer.exists?(customers(:meridian).id)
  end
end
