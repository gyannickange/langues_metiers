require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  def setup
    @admin = User.create!(email: "admin#{SecureRandom.hex(4)}@test.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
  end

  test "admin session stays alive within the idle timeout window" do
    get admin_root_path
    assert_response :success

    travel 10.minutes do
      get admin_root_path
      assert_response :success
    end
  end

  test "admin session expires after 30 minutes of inactivity" do
    get admin_root_path
    assert_response :success

    travel 31.minutes do
      get admin_root_path
      assert_redirected_to new_user_session_path
      assert_equal "Session expirée, merci de vous reconnecter.", flash[:alert]
    end
  end

  test "expired admin session is fully reset, not just redirected" do
    get admin_root_path

    travel 31.minutes do
      get admin_root_path
      assert_redirected_to new_user_session_path
    end

    get admin_root_path
    assert_redirected_to new_user_session_path
  end
end
