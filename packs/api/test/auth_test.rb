require_relative "api_case"

class AuthTest < ApiCase
  test "no token is unauthorized" do
    get "/api/v1/customers"
    assert_response :unauthorized
    assert_api_error "unauthorized", "invalid or missing token"
  end

  test "an unknown token is unauthorized" do
    get_api "/customers", token: "0" * 40
    assert_response :unauthorized
  end

  test "a malformed authorization header is unauthorized" do
    get "/api/v1/customers", headers: { "Authorization" => "Token abc" }
    assert_response :unauthorized
  end

  test "a deactivated user's token stops working" do
    users(:teddy).update!(is_active: false)
    get_api "/customers"
    assert_response :unauthorized
  end

  test "authenticated requests stamp last_used_at" do
    token = ApiToken.create!(user: users(:teddy), name: "stamped")
    assert_nil token.last_used_at

    get_api "/customers", token: token.plaintext
    assert_response :success
    assert_not_nil token.reload.last_used_at
  end

  test "the error body carries only the error object" do
    get "/api/v1/customers"
    assert_equal %w[error], body.keys
    assert_equal %w[code message], body["error"].keys
  end

  test "dispatchers cannot touch user management" do
    get_api "/users"
    assert_response :forbidden
    assert_api_error "forbidden", "admin role required"

    post_api "/users", { email: "x@example.com", name: "X", password: "dispatch-me-1" }
    assert_response :forbidden
  end

  test "dispatchers cannot delete technicians or parts" do
    delete_api "/technicians/#{technicians(:fossey).id}"
    assert_response :forbidden

    delete_api "/parts/#{parts(:valve).id}"
    assert_response :forbidden

    assert Technician.exists?(technicians(:fossey).id)
    assert Part.exists?(parts(:valve).id)
  end

  test "admins pass the same gates" do
    get_api "/users", token: @admin_token
    assert_response :success

    delete_api "/technicians/#{technicians(:fossey).id}", token: @admin_token
    assert_response :no_content
  end
end
