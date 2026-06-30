require "test_helper"

class AcademicFieldTest < ActiveSupport::TestCase
  test "auto-generates a slug from name" do
    academic_field = AcademicField.create!(name: "Langues étrangères")

    assert_equal "langues_etrangeres", academic_field.slug
  end

  test "does not regenerate the slug when the name changes later" do
    academic_field = AcademicField.create!(name: "Test")

    academic_field.update!(name: "Renamed")

    assert_equal "test", academic_field.slug
  end

  test "appends a numeric suffix when the generated slug collides" do
    AcademicField.create!(name: "Doublon")

    second = AcademicField.create!(name: "Doublon")

    assert_equal "doublon_2", second.slug
  end

  test "requires a name" do
    academic_field = AcademicField.new(slug: "test")

    assert_not academic_field.valid?
    assert_includes academic_field.errors[:name], "doit être rempli(e)"
  end

  test "requires a slug when name is blank" do
    academic_field = AcademicField.new

    assert_not academic_field.valid?
    assert_includes academic_field.errors[:slug], "doit être rempli(e)"
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

  test "auto-assigns position to one past the current max when not provided" do
    previous_max = AcademicField.maximum(:position)

    field = AcademicField.create!(slug: "field-#{SecureRandom.hex(4)}", name: "Nouvelle filière")

    assert_equal previous_max + 1, field.position
  end

  test "keeps an explicitly provided position" do
    field = AcademicField.create!(slug: "field-#{SecureRandom.hex(4)}", name: "Nouvelle filière", position: 42)

    assert_equal 42, field.position
  end
end
