require "test_helper"

class Admin::AssessmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin#{SecureRandom.hex(4)}@test.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
    @assessment = Assessment.create!(title: "Assessment #{SecureRandom.hex(4)}", active: false)
  end

  test "index links the question count to that assessment's questions" do
    get admin_assessments_path

    assert_select "a[href=?]", admin_assessment_diagnostic_questions_path(@assessment)
  end

  test "destroy redirects with see_other so Turbo does not replay the DELETE" do
    delete admin_assessment_path(@assessment)

    assert_response :see_other
    assert_redirected_to admin_assessments_path
  end
end
