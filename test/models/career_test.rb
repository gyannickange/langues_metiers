require "test_helper"

class CareerTest < ActiveSupport::TestCase
  setup do
    AcademicField.find_or_create_by!(slug: "langues") { |field| field.name = "Langues"; field.position = 1 }
    Skill.find_or_create_by!(slug: "numerique") { |skill| skill.name = "Compétences numériques"; skill.position = 6 }
  end

  test "valid factory" do
    assert Career.new(title: "Analyste & Veille", slug: "analyste-veille", status: :published, kind: :behavioral).valid?
  end

  test "invalid without title" do
    p = Career.new(slug: "test")
    assert_not p.valid?
    assert_includes p.errors[:title], "doit être rempli(e)"
  end

  test "invalid without slug" do
    p = Career.new(title: "Test")
    assert_not p.valid?
    assert_includes p.errors[:slug], "doit être rempli(e)"
  end

  test "unique slug" do
    Career.create!(title: "P1", slug: "my-slug", status: :published, kind: :behavioral)
    assert_not Career.new(title: "P2", slug: "my-slug", status: :published, kind: :behavioral).valid?
  end

  test "slug is parameterized before validation" do
    p = Career.create!(title: "Test", slug: "test-#{SecureRandom.hex(4)}", status: :published, kind: :behavioral)
    p.update!(slug: "Un Slug Invalide")
    assert_equal "un-slug-invalide", p.slug
  end

  test "has_many trajectories" do
    assert_respond_to Career.new, :trajectories
  end

  test "diagnostic scope returns only careers with academic_field_slug" do
    c1 = Career.create!(title: "Métier A", academic_field_slug: "langues", status: :published, kind: :profession)
    c2 = Career.create!(title: "Métier B", status: :published, kind: :profession)
    assert_includes Career.diagnostic, c1
    assert_not_includes Career.diagnostic, c2
  end

  test "disc_types defaults to empty array" do
    c = Career.create!(title: "Test Career #{SecureRandom.hex(4)}", status: :published, kind: :profession)
    assert_equal [], c.disc_types
  end

  test "required_skills defaults to empty array" do
    c = Career.create!(title: "Test Career #{SecureRandom.hex(4)}", status: :published, kind: :profession)
    assert_equal [], c.required_skills
  end

  test "affirmations defaults to empty array" do
    c = Career.create!(title: "Test Career #{SecureRandom.hex(4)}", status: :published, kind: :profession)
    assert_equal [], c.affirmations
  end

  test "affirmations_text round-trips through newlines, stripping blanks" do
    c = Career.new
    c.affirmations_text = "Première\n  Deuxième  \n\n Troisième \n"
    assert_equal [ "Première", "Deuxième", "Troisième" ], c.affirmations
    assert_equal "Première\nDeuxième\nTroisième", c.affirmations_text
  end

  test "key_skills_text round-trips through newlines" do
    c = Career.new
    c.key_skills_text = "Leadership\nGestion de projet\n"
    assert_equal [ "Leadership", "Gestion de projet" ], c.key_skills
  end

  test "normalizes array fields by removing blank entries" do
    c = Career.new(title: "X", slug: "x-#{SecureRandom.hex(4)}", kind: :profession,
                   disc_types: [ "D", "", nil ], required_skills: [ "numerique", "" ])
    c.valid?
    assert_equal [ "D" ], c.disc_types
    assert_equal [ "numerique" ], c.required_skills
  end

  test "rejects disc_types outside the DISC vocabulary" do
    c = Career.new(title: "X", slug: "x-#{SecureRandom.hex(4)}", kind: :profession, disc_types: [ "Z" ])
    assert_not c.valid?
    assert_includes c.errors[:disc_types].join, "Z"
  end

  test "rejects required_skills outside the vocabulary" do
    c = Career.new(title: "X", slug: "x-#{SecureRandom.hex(4)}", kind: :profession, required_skills: [ "bogus" ])
    assert_not c.valid?
    assert_includes c.errors[:required_skills].join, "bogus"
  end

  test "rejects academic_field_slug outside the vocabulary" do
    c = Career.new(title: "X", slug: "x-#{SecureRandom.hex(4)}", kind: :profession, academic_field_slug: "nope")
    assert_not c.valid?
    assert_not_empty c.errors[:academic_field_slug]
  end

  test "behavioral profile is valid with no academic_field_slug" do
    c = Career.new(title: "X", slug: "x-#{SecureRandom.hex(4)}", kind: :behavioral, academic_field_slug: nil)
    assert c.valid?, c.errors.full_messages.to_sentence
  end
end
