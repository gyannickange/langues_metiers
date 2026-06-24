require "test_helper"

class Admin::AcademicFieldsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin#{SecureRandom.hex(4)}@test.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
    @academic_field = AcademicField.create!(slug: "test-#{SecureRandom.hex(4)}", name: "Academic field test", position: 99)
  end

  test "index renders without missing translations" do
    get admin_academic_fields_path

    assert_response :success
    assert_no_match "translation missing", response.body
  end

  test "show renders without missing translations" do
    get admin_academic_field_path(@academic_field)

    assert_response :success
    assert_no_match "translation missing", response.body
  end

  test "create persists a new academic_field" do
    assert_difference "AcademicField.count", 1 do
      post admin_academic_fields_path, params: { academic_field: { slug: "new-academic-field", name: "New academic field", position: 9 } }
    end

    assert_redirected_to admin_academic_field_path(AcademicField.find_by!(slug: "new-academic-field"))
  end

  test "update persists changes" do
    patch admin_academic_field_path(@academic_field), params: { academic_field: { name: "Nom mis à jour" } }

    assert_redirected_to admin_academic_field_path(@academic_field)
    assert_equal "Nom mis à jour", @academic_field.reload.name
  end

  test "destroy removes the academic_field" do
    assert_difference "AcademicField.count", -1 do
      delete admin_academic_field_path(@academic_field)
    end

    assert_redirected_to admin_academic_fields_path
  end

  test "sidebar includes a link to Academic fields and highlights it as active" do
    get admin_academic_fields_path

    assert_response :success
    assert_select "nav a[href='#{admin_academic_fields_path}']", text: /Academic fields/
    assert_select "nav a[href='#{admin_academic_fields_path}'].bg-\\[var\\(--color-primary\\)\\]\\/10"
  end

  test "sidebar link to Academic fields is not active on another admin page" do
    get admin_root_path

    assert_response :success
    assert_select "nav a[href='#{admin_academic_fields_path}']", text: /Academic fields/
    assert_select "nav a[href='#{admin_academic_fields_path}'].bg-\\[var\\(--color-primary\\)\\]\\/10", count: 0
  end
end
