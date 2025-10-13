require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  test "creation mints a plaintext and stores only its digest" do
    token = ApiToken.create!(user: users(:teddy), name: "reporting")

    assert_match(/\A\h{40}\z/, token.plaintext)
    assert_equal ApiToken.digest(token.plaintext), token.token_hash
    assert_not_equal token.plaintext, token.token_hash
  end

  test "a reloaded token has no plaintext" do
    token = ApiToken.create!(user: users(:teddy), name: "reporting")
    assert_nil ApiToken.find(token.id).plaintext
  end

  test "authenticate finds the owner by plaintext" do
    token = ApiToken.create!(user: users(:teddy), name: "reporting")

    assert_equal token, ApiToken.authenticate(token.plaintext)
    assert_nil ApiToken.authenticate("0" * 40)
    assert_nil ApiToken.authenticate(nil)
    assert_nil ApiToken.authenticate("")
  end

  test "tokens of deactivated users stop working" do
    token = ApiToken.create!(user: users(:teddy), name: "reporting")
    users(:teddy).update!(is_active: false)

    assert_nil ApiToken.authenticate(token.plaintext)
  end

  test "name is required and bounded" do
    assert_not ApiToken.new(user: users(:teddy), name: " ").valid?
    assert_not ApiToken.new(user: users(:teddy), name: "x" * 81).valid?
  end

  test "deleting a user removes their tokens" do
    ApiToken.create!(user: users(:teddy), name: "reporting")
    users(:teddy).destroy!
    assert_equal 0, ApiToken.where(user_id: users(:teddy).id).count
  end
end
