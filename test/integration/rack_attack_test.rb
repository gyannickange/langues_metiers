require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
  end

  teardown do
    Rack::Attack.enabled = false
  end

  TURBO_STREAM_HEADERS = { "Accept" => "text/vnd.turbo-stream.html" }.freeze

  test "throttles repeated OTP verification attempts for the same email" do
    5.times do
      post "/login/verify_otp", params: { email: "target@test.com", otp_code: "000000" }, headers: TURBO_STREAM_HEADERS
      assert_response :success
    end

    post "/login/verify_otp", params: { email: "target@test.com", otp_code: "000000" }, headers: TURBO_STREAM_HEADERS
    assert_response :too_many_requests
  end

  test "throttles repeated OTP requests for the same email" do
    3.times do
      post "/login/request_otp", params: { email: "target2@test.com" }, headers: TURBO_STREAM_HEADERS
      assert_response :success
    end

    post "/login/request_otp", params: { email: "target2@test.com" }, headers: TURBO_STREAM_HEADERS
    assert_response :too_many_requests
  end

  test "does not throttle unrelated admin traffic under the OTP limits" do
    admin = User.create!(email: "admin#{SecureRandom.hex(4)}@test.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: admin.email, password: "password123" } }

    5.times { get admin_root_path }

    get admin_root_path
    assert_response :success
  end

  test "throttles excessive traffic to the admin namespace by IP" do
    admin = User.create!(email: "admin#{SecureRandom.hex(4)}@test.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: admin.email, password: "password123" } }

    300.times { Rack::Attack.cache.count("admin/ip:127.0.0.1", 5.minutes) }

    get admin_root_path
    assert_response :too_many_requests
  end
end
