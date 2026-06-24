require "test_helper"

class Admin::SkillsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin#{SecureRandom.hex(4)}@test.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
    @skill = Skill.create!(name: "Skill #{SecureRandom.hex(4)}", slug: "skill-#{SecureRandom.hex(4)}")
  end

  test "index renders without missing translations" do
    get admin_skills_path

    assert_response :success
    assert_no_match "translation missing", response.body
  end
end
