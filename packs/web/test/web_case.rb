require "test_helper"

class WebCase < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def sign_in_dispatcher = sign_in(users(:teddy))

  def sign_in_admin = sign_in(users(:marisol))
end
