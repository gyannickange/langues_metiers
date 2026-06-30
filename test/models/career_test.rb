require "test_helper"

class CareerTest < ActiveSupport::TestCase
  setup do
    AcademicField.find_or_create_by!(slug: "langues") { |field| field.name = "Langues"; field.position = 1 }
    Skill.find_or_create_by!(slug: "numerique") { |skill| skill.name = "Compétences numériques"; skill.position = 6 }
  end

  test "valid factory" do
    assert Career.new(title: "Analyste & Veille", status: :published).valid?
  end

  test "invalid without title" do
    p = Career.new
    assert_not p.valid?
    assert_includes p.errors[:title], "doit être rempli(e)"
  end

  test "has_many trajectories" do
    assert_respond_to Career.new, :trajectories
  end

  test "auto-generates a slug from title" do
    career = Career.create!(title: "Traducteur / Interprète", status: :published)

    assert_equal "traducteur_interprete", career.slug
  end

  test "does not regenerate the slug when the title changes later" do
    career = Career.create!(title: "Test", status: :published)

    career.update!(title: "Renamed")

    assert_equal "test", career.slug
  end

  test "appends a numeric suffix when the generated slug collides" do
    Career.create!(title: "Doublon", status: :published)

    second = Career.create!(title: "Doublon", status: :published)

    assert_equal "doublon_2", second.slug
  end

  test "requires a unique slug" do
    Career.create!(title: "Premier", slug: "test-slug", status: :published)
    duplicate = Career.new(title: "Second", slug: "test-slug", status: :published)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "est déjà utilisé(e)"
  end

  test "diagnostic scope returns only careers with academic_field_slug" do
    c1 = Career.create!(title: "Métier A", academic_field_slug: "langues", status: :published)
    c2 = Career.create!(title: "Métier B", status: :published)
    assert_includes Career.diagnostic, c1
    assert_not_includes Career.diagnostic, c2
  end

  test "disc_types defaults to empty array" do
    c = Career.create!(title: "Test Career #{SecureRandom.hex(4)}", status: :published)
    assert_equal [], c.disc_types
  end

  test "required_skills defaults to empty array" do
    c = Career.create!(title: "Test Career #{SecureRandom.hex(4)}", status: :published)
    assert_equal [], c.required_skills
  end

  test "affirmations defaults to empty array" do
    c = Career.create!(title: "Test Career #{SecureRandom.hex(4)}", status: :published)
    assert_equal [], c.affirmations
  end

  test "affirmations_text round-trips through newlines, stripping blanks" do
    c = Career.new
    c.affirmations_text = "Première\n  Deuxième  \n\n Troisième \n"
    assert_equal [ "Première", "Deuxième", "Troisième" ], c.affirmations
    assert_equal "Première\nDeuxième\nTroisième", c.affirmations_text
  end

  test "normalizes array fields by removing blank entries" do
    c = Career.new(title: "X", disc_types: [ "D", "", nil ], required_skills: [ "numerique", "" ])
    c.valid?
    assert_equal [ "D" ], c.disc_types
    assert_equal [ "numerique" ], c.required_skills
  end

  test "rejects disc_types outside the DISC vocabulary" do
    c = Career.new(title: "X", disc_types: [ "Z" ])
    assert_not c.valid?
    assert_includes c.errors[:disc_types].join, "Z"
  end

  test "rejects required_skills outside the vocabulary" do
    c = Career.new(title: "X", required_skills: [ "bogus" ])
    assert_not c.valid?
    assert_includes c.errors[:required_skills].join, "bogus"
  end

  test "rejects academic_field_slug outside the vocabulary" do
    c = Career.new(title: "X", academic_field_slug: "nope")
    assert_not c.valid?
    assert_not_empty c.errors[:academic_field_slug]
  end

  test "versions on update" do
    career = Career.create!(title: "Traducteur", status: :published, academic_field_slug: "langues")

    assert_difference -> { career.versions.count }, 1 do
      career.update!(title: "Traducteur juridique")
    end
  end
end
