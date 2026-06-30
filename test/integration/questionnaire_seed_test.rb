require "test_helper"

class QuestionnaireSeedTest < ActiveSupport::TestCase
  test "seed matches the questionnaire source data exactly" do
    load Rails.root.join("db/seeds.rb")

    assessment = Assessment.find_by!(title: "Diagnostic Langues & Métiers")
    questions = assessment.diagnostic_questions.active

    assert_equal 16, questions.interest.count
    assert_equal 16, questions.disc.count
    assert_equal 197, questions.skill.count

    academic_field_tally = questions.interest.pluck(:academic_field_slug).tally
    assert_equal Diagnostics::Vocabulary.academic_field_slugs.sort, academic_field_tally.keys.sort
    assert academic_field_tally.values.all? { |count| count == 2 }, "Each academic field should have exactly 2 questions"

    careers = Career.diagnostic.published
    assert_equal 37, careers.count
    assert careers.exists?(title: "Guide touristique")
    assert_not careers.exists?(title: "Guide touristique / patrimonial")
    assert_equal %w[gestion_projet numerique gestion_projet],
      careers.find_by!(title: "Chef de projet e-learning").required_skills

    assert_equal 49, Skill.count
    generic_skill_slugs = Skill.order(:position).limit(12).pluck(:slug)
    assert_equal %w[langues_etrangeres communication_ecrite communication_orale analyse_donnees gestion_projet
      numerique negociation creativite ecoute rigueur_scientifique culture_generale droit_politiques],
      generic_skill_slugs

    generic_questions = questions.skill.where(skill_slug: generic_skill_slugs)
    assert_equal 12, generic_questions.count
    assert_equal [ "Langues étrangères", "Communication écrite", "Communication orale", "Analyse de données",
      "Gestion de projet", "Compétences numériques", "Négociation", "Créativité", "Écoute active",
      "Rigueur et méthode", "Culture générale", "Droit et politiques publiques" ],
      generic_questions.ordered.map { |question| question.options.dig(0, "label") }

    metier_skill_slugs = Skill.order(:position).offset(12).pluck(:slug)
    assert_equal 37, metier_skill_slugs.uniq.count

    metier_questions = questions.skill.where(skill_slug: metier_skill_slugs)
    assert_equal 185, metier_questions.count
    assert metier_questions.reorder(nil).group(:skill_slug).count.values.all? { |count| count == 5 },
      "Each métier skill should have exactly 5 questions"

    traducteur_questions = metier_questions.where(skill_slug: "traducteur").ordered
    assert_equal 5, traducteur_questions.count
    assert_equal "Traducteur / Interprète", traducteur_questions.first.options.dig(0, "label")
    assert_equal "Je suis passionné(e) par les nuances linguistiques entre les langues.",
      traducteur_questions.first.text
  end
end
