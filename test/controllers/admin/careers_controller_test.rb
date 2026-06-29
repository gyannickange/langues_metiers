require "test_helper"

class Admin::CareersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin#{SecureRandom.hex(4)}@test.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
    @metier = Career.create!(title: "Métier #{SecureRandom.hex(4)}", status: :published)
  end

  test "update persists the four diagnostic fields on a career" do
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

  test "update persists first_action and premium_pitch" do
    patch admin_career_path(@metier), params: { career: {
      first_action: "Faites X",
      premium_pitch: "Le premium fait Y"
    } }

    assert_redirected_to admin_careers_path
    @metier.reload
    assert_equal "Faites X", @metier.first_action
    assert_equal "Le premium fait Y", @metier.premium_pitch
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

  test "update records the signed-in admin as whodunnit" do
    patch admin_career_path(@metier), params: { career: { title: "Titre modifié" } }

    assert_equal @admin.id.to_s, @metier.versions.last.whodunnit
  end

  test "edit renders version history after an update" do
    @metier.update!(title: "Titre modifié")

    get edit_admin_career_path(@metier)

    assert_select "h3", text: "Historique des modifications"
  end
end
