require "test_helper"

class SkillTest < ActiveSupport::TestCase
  test "requires a slug" do
    skill = Skill.new(name: "Test")

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
