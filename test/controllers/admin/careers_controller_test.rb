require "test_helper"

class Admin::CareersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin#{SecureRandom.hex(4)}@test.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
    @metier = Career.create!(title: "Métier #{SecureRandom.hex(4)}", status: :published, kind: :profession)
    @profil = Career.create!(title: "Profil #{SecureRandom.hex(4)}", slug: "profil-#{SecureRandom.hex(4)}",
                             status: :published, kind: :behavioral)
  end

  test "update persists the four diagnostic fields on a profession career" do
    patch admin_career_path(@metier), params: { career: {
      filiere_slug: "langues",
      disc_types: ["C", "S"],
      required_competences: ["langues_etrangeres", "communication_ecrite"],
      affirmations_text: "Affirmation une\nAffirmation deux"
    } }

    assert_redirected_to admin_careers_path
    @metier.reload
    assert_equal "langues", @metier.filiere_slug
    assert_equal ["C", "S"], @metier.disc_types
    assert_equal ["langues_etrangeres", "communication_ecrite"], @metier.required_competences
    assert_equal ["Affirmation une", "Affirmation deux"], @metier.affirmations
  end

  test "update with invalid filiere re-renders with an error" do
    patch admin_career_path(@metier), params: { career: { filiere_slug: "bogus" } }

    assert_response :unprocessable_entity
    assert_select "li", text: /filière/
  end

  test "update persists behavioral profile fields" do
    patch admin_career_path(@profil), params: { career: {
      first_action: "Faites X",
      premium_pitch: "Le premium fait Y",
      key_skills_text: "Leadership\nCommunication"
    } }

    assert_redirected_to admin_careers_path
    @profil.reload
    assert_equal "Faites X", @profil.first_action
    assert_equal ["Leadership", "Communication"], @profil.key_skills
  end
end
