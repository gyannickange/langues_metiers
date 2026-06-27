require "test_helper"

class Diagnostics::VocabularyTest < ActiveSupport::TestCase
  setup do
    [
      [ "langues", "Langues", 1 ],
      [ "geo", "Géographie & territoires", 2 ],
      [ "socio", "Sociologie", 3 ],
      [ "lettres", "Lettres", 4 ],
      [ "psycho", "Psychologie", 5 ],
      [ "philo", "Philosophie", 6 ],
      [ "histoire", "Histoire", 7 ],
      [ "edu", "Sciences de l'éducation", 8 ]
    ].each do |slug, name, position|
      AcademicField.find_or_create_by!(slug: slug) { |field| field.name = name; field.position = position }
    end

    [
      [ "langues_etrangeres", "Langues étrangères", 1 ],
      [ "communication_ecrite", "Communication écrite", 2 ],
      [ "communication_orale", "Communication orale", 3 ],
      [ "analyse_donnees", "Analyse de données", 4 ],
      [ "gestion_projet", "Gestion de projet", 5 ],
      [ "numerique", "Compétences numériques", 6 ],
      [ "negociation", "Négociation", 7 ],
      [ "creativite", "Créativité", 8 ],
      [ "ecoute", "Écoute active", 9 ],
      [ "rigueur_scientifique", "Rigueur et méthode", 10 ],
      [ "culture_generale", "Culture générale", 11 ],
      [ "droit_politiques", "Droit et politiques publiques", 12 ]
    ].each do |slug, name, position|
      Skill.find_or_create_by!(slug: slug) { |skill| skill.name = name; skill.position = position }
    end
  end

  test "academic_field slugs match the eight diagnostic academic_fields" do
    assert_equal %w[langues geo socio lettres psycho philo histoire edu].sort,
                 Diagnostics::Vocabulary.academic_field_slugs.sort
  end

  test "skill slugs cover the twelve diagnostic skills" do
    assert_equal 12, Diagnostics::Vocabulary.skill_slugs.length
    assert_includes Diagnostics::Vocabulary.skill_slugs, "langues_etrangeres"
    assert_includes Diagnostics::Vocabulary.skill_slugs, "droit_politiques"
  end

  test "disc type slugs are the four DISC letters" do
    assert_equal %w[D I S C], Diagnostics::Vocabulary.disc_type_slugs
  end

  test "option helpers return [label, slug] pairs for selects" do
    assert_equal [ "Langues", "langues" ], Diagnostics::Vocabulary.academic_field_options.first
    assert_equal [ "Dominant", "D" ], Diagnostics::Vocabulary.disc_type_options.first
    label, slug = Diagnostics::Vocabulary.skill_options.first
    assert_equal "Langues étrangères", label
    assert_equal "langues_etrangeres", slug
  end
end
