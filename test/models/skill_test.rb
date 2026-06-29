require "test_helper"

class SkillTest < ActiveSupport::TestCase
  test "auto-generates a slug from name" do
    skill = Skill.create!(name: "Communication Interculturelle")

    assert_equal "communication_interculturelle", skill.slug
  end

  test "does not overwrite an explicitly provided slug" do
    skill = Skill.create!(name: "Test", slug: "custom-slug")

    assert_equal "custom-slug", skill.slug
  end

  test "does not regenerate the slug when the name changes later" do
    skill = Skill.create!(name: "Test")

    skill.update!(name: "Renamed")

    assert_equal "test", skill.slug
  end

  test "appends a numeric suffix when the generated slug collides" do
    Skill.create!(name: "Doublon")

    second = Skill.create!(name: "Doublon")

    assert_equal "doublon_2", second.slug
  end

  test "requires a slug when name is blank" do
    skill = Skill.new

    assert_not skill.valid?
    assert_includes skill.errors[:slug], "doit être rempli(e)"
  end

  test "requires a unique slug" do
    Skill.create!(slug: "test-slug", name: "Premier")
    duplicate = Skill.new(slug: "test-slug", name: "Second")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "est déjà utilisé(e)"
  end

  test "versions on update" do
    skill = Skill.create!(name: "Numérique", slug: "skill-#{SecureRandom.hex(4)}")

    assert_difference -> { skill.versions.count }, 1 do
      skill.update!(name: "Compétences numériques")
    end
  end
end
