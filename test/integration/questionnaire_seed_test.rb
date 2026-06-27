require "test_helper"

class QuestionnaireSeedTest < ActiveSupport::TestCase
  test "seed matches the questionnaire source data exactly" do
    load Rails.root.join("db/seeds.rb")

    assessment = Assessment.find_by!(title: "Diagnostic Langues & Métiers")
    questions = assessment.diagnostic_questions.active

    assert_equal 16, questions.interest.count
    assert_equal 16, questions.disc.count
    assert_equal 12, questions.skill.count

    academic_field_tally = questions.interest.pluck(:academic_field_slug).tally
    assert_equal Diagnostics::Vocabulary.academic_field_slugs.sort, academic_field_tally.keys.sort
    assert academic_field_tally.values.all? { |count| count == 2 }, "Each academic field should have exactly 2 questions"

    careers = Career.diagnostic.published
    assert_equal 37, careers.count
    assert careers.exists?(title: "Guide touristique")
    assert_not careers.exists?(title: "Guide touristique / patrimonial")
    assert_equal %w[gestion_projet numerique gestion_projet],
      careers.find_by!(title: "Chef de projet e-learning").required_skills
    assert_equal [ "Langues étrangères", "Communication écrite", "Communication orale", "Analyse de données",
      "Gestion de projet", "Compétences numériques", "Négociation", "Créativité", "Écoute active",
      "Rigueur et méthode", "Culture générale", "Droit et politiques publiques" ],
      questions.skill.ordered.map { |question| question.options.dig(0, "label") }
  end
end
