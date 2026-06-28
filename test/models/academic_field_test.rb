require "test_helper"

class AcademicFieldTest < ActiveSupport::TestCase
  test "requires a slug" do
    academic_field = AcademicField.new(name: "Test")

    assert_not academic_field.valid?
    assert_includes academic_field.errors[:slug], "doit être rempli(e)"
  end

  test "requires a name" do
    academic_field = AcademicField.new(slug: "test")

    assert_not academic_field.valid?
    assert_includes academic_field.errors[:name], "doit être rempli(e)"
  end

  test "requires a unique slug" do
    AcademicField.create!(slug: "test-slug", name: "Premier")
    duplicate = AcademicField.new(slug: "test-slug", name: "Second")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "est déjà utilisé(e)"
  end

  test "versions on update" do
    field = AcademicField.create!(slug: "field-#{SecureRandom.hex(4)}", name: "Langues")

    assert_difference -> { field.versions.count }, 1 do
      field.update!(name: "Langues étrangères")
    end
  end
end
