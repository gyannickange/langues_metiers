require "test_helper"

class Admin::MobileOperatorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin#{SecureRandom.hex(4)}@test.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
    @operator = MobileOperator.create!(name: "Operator #{SecureRandom.hex(4)}", code: "op#{SecureRandom.hex(2)}", country_code: "CI")
  end

  test "destroy redirects with see_other so Turbo does not replay the DELETE" do
    delete admin_mobile_operator_path(@operator)

    assert_response :see_other
    assert_redirected_to admin_mobile_operators_path
  end

  test "index paginates the operators" do
    25.times { |i| MobileOperator.create!(name: "Operator #{i}", code: "op#{i}", country_code: "CI") }

    get admin_mobile_operators_path

    assert_response :success
    assert_select "nav[aria-label='Pagination']"
    assert_no_match "translation missing", response.body
  end
end
