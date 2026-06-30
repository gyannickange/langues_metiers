require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email: "admin#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      role: :admin
    )
    @user = User.create!(
      email: "user#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      role: :user
    )
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
  end

  test "index renders successfully" do
    get admin_users_path
    assert_response :success
  end

  test "show renders the user page" do
    get admin_user_path(@user)
    assert_response :success
    assert_select "h1", text: @user.email
  end

  test "update changes the user role" do
    patch admin_user_path(@user), params: { user: { role: "admin" } }
    assert_redirected_to admin_user_path(@user)
    assert_equal "admin", @user.reload.role
  end

  test "update ignores unpermitted params" do
    original_email = @user.email
    patch admin_user_path(@user), params: { user: { role: "admin", email: "hacked@evil.com" } }
    assert_equal original_email, @user.reload.email
  end
end
