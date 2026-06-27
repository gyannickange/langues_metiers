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
      academic_field_slug: "langues",
      disc_types: [ "C", "S" ],
      required_skills: [ "langues_etrangeres", "communication_ecrite" ],
      affirmations_text: "Affirmation une\nAffirmation deux"
    } }

    assert_redirected_to admin_careers_path
    @metier.reload
    assert_equal "langues", @metier.academic_field_slug
    assert_equal [ "C", "S" ], @metier.disc_types
    assert_equal [ "langues_etrangeres", "communication_ecrite" ], @metier.required_skills
    assert_equal [ "Affirmation une", "Affirmation deux" ], @metier.affirmations
  end

  test "update with invalid academic_field re-renders with an error" do
    patch admin_career_path(@metier), params: { career: { academic_field_slug: "bogus" } }

    assert_response :unprocessable_entity
    assert_select "li", text: /academic field/
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
    assert_equal [ "Leadership", "Communication" ], @profil.key_skills
  end

  test "update redirects with see_other so Turbo does not replay the PATCH" do
    patch admin_career_path(@metier), params: { career: { title: "Nouveau titre" } }

    assert_response :see_other
  end

  test "destroy redirects with see_other so Turbo does not replay the DELETE" do
    delete admin_career_path(@metier)

    assert_response :see_other
    assert_redirected_to admin_careers_path
  end

  test "index renders without missing translations" do
    get admin_careers_path

    assert_response :success
    assert_no_match "translation missing", response.body
  end

  test "new renders without missing translations" do
    get new_admin_career_path

    assert_response :success
    assert_no_match "translation missing", response.body
  end

  test "edit renders without missing translations" do
    get edit_admin_career_path(@metier)

    assert_response :success
    assert_no_match "translation missing", response.body
  end
end
