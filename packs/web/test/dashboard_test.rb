require_relative "web_case"

class DashboardTest < WebCase
  test "signed-out visitors land on the sign-in form" do
    get root_path
    assert_redirected_to new_user_session_path
  end

  test "signing in reaches the board" do
    post user_session_path, params: { user: { email: users(:teddy).email, password: "dispatch-me-1" } }
    follow_redirect!
    assert_response :success
    assert_select "h1", "Dispatch board"
    assert_select ".lane", 6
  end

  test "a deactivated user cannot sign in" do
    users(:teddy).update!(is_active: false)
    post user_session_path, params: { user: { email: users(:teddy).email, password: "dispatch-me-1" } }
    assert_not response.location&.end_with?(root_path)
    get root_path
    assert_redirected_to new_user_session_path
  end

  test "the board shows open jobs and empty states" do
    sign_in_dispatcher
    get root_path
    assert_select "td", text: "Furnace not igniting"
    assert_select ".card p.muted", text: "No appointments today."
  end

  test "dispatchers do not see the users link" do
    sign_in_dispatcher
    get root_path
    assert_select "nav a", text: "Users", count: 0

    sign_in_admin
    get root_path
    assert_select "nav a", text: "Users", count: 1
  end
end
