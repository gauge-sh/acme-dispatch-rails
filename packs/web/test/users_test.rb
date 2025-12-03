require_relative "web_case"

class UsersTest < WebCase
  test "the whole area is admin-only" do
    sign_in_dispatcher
    get users_path
    assert_redirected_to root_path

    get user_path(users(:teddy))
    assert_redirected_to root_path
  end

  test "admins create accounts" do
    sign_in_admin
    post users_path, params: { user: { name: "Nadia Osei", email: "nadia@acme-dispatch.example", password: "dispatch-me-1", role: "dispatcher" } }
    user = User.find_by!(email: "nadia@acme-dispatch.example")
    assert_redirected_to user_path(user)
    assert user.valid_password?("dispatch-me-1")
  end

  test "editing without a password keeps the old one" do
    sign_in_admin
    patch user_path(users(:teddy)), params: { user: { name: "Ted Marsh", password: "" } }
    assert_redirected_to user_path(users(:teddy))
    assert users(:teddy).reload.valid_password?("dispatch-me-1")
    assert_equal "Ted Marsh", users(:teddy).name
  end

  test "an admin cannot change their own role or deactivate themselves" do
    sign_in_admin
    patch user_path(users(:marisol)), params: { user: { role: "dispatcher" } }
    assert_response :unprocessable_entity
    assert_select ".errors li", text: "you cannot change your own role"

    patch user_path(users(:marisol)), params: { user: { is_active: "0" } }
    assert_response :unprocessable_entity
    assert_select ".errors li", text: "you cannot deactivate yourself"
    assert users(:marisol).reload.is_active
  end

  test "admins cannot delete themselves, and spare admins can go" do
    spare = User.create!(email: "iris@acme-dispatch.example", name: "Iris Chao", password: "dispatch-me-1", role: "admin")
    sign_in spare

    delete user_path(spare)
    follow_redirect!
    assert_select ".flash-alert", text: /You cannot delete your own account/
    assert User.exists?(spare.id)

    delete user_path(users(:marisol))
    assert_redirected_to users_path
    assert_not User.exists?(users(:marisol).id)
  end

  test "demoting the last active admin fails on the form" do
    # Deactivate the other admin path: teddy promoted then deactivated leaves
    # marisol the last active admin; editing her role must fail validation.
    sign_in_admin
    users(:marisol).update_column(:role, "admin")
    spare = User.create!(email: "iris@acme-dispatch.example", name: "Iris Chao", password: "dispatch-me-1", role: "admin")
    sign_in spare

    patch user_path(users(:marisol)), params: { user: { role: "dispatcher" } }
    assert_redirected_to user_path(users(:marisol))

    # spare is now the last active admin; nobody else can demote them either
    # because any actor doing so would be spare themselves. The model guard
    # still holds if it happens programmatically.
    error = assert_raises(Dispatch::ValidationFailed) { spare.reload.destroy }
    assert_equal "cannot remove the last active admin", error.message
  end

  test "issuing a token reveals the plaintext exactly once" do
    sign_in_admin
    post user_api_tokens_path(users(:teddy)), params: { api_token: { name: "reporting" } }
    follow_redirect!

    token = users(:teddy).api_tokens.sole
    plaintext = flash[:notice][/\h{40}\z/]
    assert plaintext
    assert_equal ApiToken.digest(plaintext), token.token_hash
    assert_select ".flash-notice", text: /Copy it now/

    get user_path(users(:teddy))
    assert_no_match plaintext, response.body
  end

  test "revoking a token removes it" do
    sign_in_admin
    token = ApiToken.create!(user: users(:teddy), name: "old")
    delete api_token_path(token)
    assert_not ApiToken.exists?(token.id)
  end
end
