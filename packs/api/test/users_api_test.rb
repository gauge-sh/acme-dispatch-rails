require_relative "api_case"

class UsersApiTest < ApiCase
  test "lists users without any password material" do
    get_api "/users", token: @admin_token
    user = body["items"].first
    assert_equal %w[id email name role is_active created_at updated_at], user.keys
    assert_nil response.body[/password/]
    assert_nil response.body[/encrypted/]
  end

  test "filters by role and activity" do
    get_api "/users", token: @admin_token, role: "admin"
    assert_equal [ users(:marisol).id ], body["items"].map { |u| u["id"] }

    users(:teddy).update!(is_active: false)
    get_api "/users", token: @admin_token, is_active: "false"
    assert_equal [ users(:teddy).id ], body["items"].map { |u| u["id"] }
  end

  test "creates a dispatcher by default" do
    post_api "/users", { email: "nadia@acme-dispatch.example", name: "Nadia Osei", password: "dispatch-me-1" }, token: @admin_token
    assert_response :created
    assert_equal "dispatcher", body["role"]
    assert User.find(body["id"]).valid_password?("dispatch-me-1")
  end

  test "duplicate emails are refused case-insensitively" do
    post_api "/users", { email: "MARISOL@acme-dispatch.example", name: "Copy", password: "dispatch-me-1" }, token: @admin_token
    assert_response :bad_request
    assert_equal "has already been taken", body.dig("error", "fields", "email")
  end

  test "updates role and activity for another user" do
    patch_api "/users/#{users(:teddy).id}", { role: "admin" }, token: @admin_token
    assert_response :success
    assert_equal "admin", body["role"]

    patch_api "/users/#{users(:teddy).id}", { is_active: false }, token: @admin_token
    assert_response :success
    assert_not body["is_active"]
  end

  test "an admin cannot change their own role" do
    patch_api "/users/#{users(:marisol).id}", { role: "dispatcher" }, token: @admin_token
    assert_response :bad_request
    assert_api_error "validation_failed", "you cannot change your own role"
    assert users(:marisol).reload.admin?
  end

  test "an admin cannot deactivate themselves" do
    patch_api "/users/#{users(:marisol).id}", { is_active: false }, token: @admin_token
    assert_response :bad_request
    assert_api_error "validation_failed", "you cannot deactivate yourself"
    assert users(:marisol).reload.is_active
  end

  test "restating your own current role is not an error" do
    patch_api "/users/#{users(:marisol).id}", { role: "admin", name: "Marisol V." }, token: @admin_token
    assert_response :success
    assert_equal "Marisol V.", body["name"]
  end

  test "the last active admin cannot be deleted" do
    delete_api "/users/#{users(:marisol).id}", token: @admin_token
    assert_response :bad_request
    assert_api_error "validation_failed", "cannot remove the last active admin"
  end

  test "another admin can be demoted while a second one remains" do
    second_admin = User.create!(email: "iris@acme-dispatch.example", name: "Iris Chao", password: "dispatch-me-1", role: "admin")
    token = ApiToken.create!(user: second_admin, name: "second").plaintext

    patch_api "/users/#{users(:marisol).id}", { role: "dispatcher" }, token: token
    assert_response :success

    # Over the API the self-guard always fires before the last-admin check —
    # the model-level guard is exercised in the unit tests.
    patch_api "/users/#{second_admin.id}", { role: "dispatcher" }, token: token
    assert_response :bad_request
    assert_api_error "validation_failed", "you cannot change your own role"
  end

  test "a spare admin can be deleted" do
    spare = User.create!(email: "iris@acme-dispatch.example", name: "Iris Chao", password: "dispatch-me-1", role: "admin")
    delete_api "/users/#{spare.id}", token: @admin_token
    assert_response :no_content
    assert_not User.exists?(spare.id)
  end

  test "password updates go through devise" do
    patch_api "/users/#{users(:teddy).id}", { password: "new-password-9" }, token: @admin_token
    assert_response :success
    assert users(:teddy).reload.valid_password?("new-password-9")

    patch_api "/users/#{users(:teddy).id}", { password: nil, name: "Ted Marsh" }, token: @admin_token
    assert_response :success
    assert users(:teddy).reload.valid_password?("new-password-9")
  end
end
