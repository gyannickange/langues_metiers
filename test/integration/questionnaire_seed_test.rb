require "test_helper"

class QuestionnaireSeedTest < ActiveSupport::TestCase
  FILIERES = [
    { "label" => "Langues", "filiere_slug" => "langues", "icon" => "🌍" },
    { "label" => "Géographie / Aménagement", "filiere_slug" => "geo", "icon" => "🗺️" },
    { "label" => "Sociologie / Anthropologie", "filiere_slug" => "socio", "icon" => "👥" },
    { "label" => "Lettres Modernes", "filiere_slug" => "lettres", "icon" => "📚" },
    { "label" => "Psychologie", "filiere_slug" => "psycho", "icon" => "🧠" },
    { "label" => "Philosophie", "filiere_slug" => "philo", "icon" => "💡" },
    { "label" => "Histoire / Archéologie", "filiere_slug" => "histoire", "icon" => "🏛️" },
    { "label" => "Sciences de l'Éducation", "filiere_slug" => "edu", "icon" => "🎓" }
  ].freeze

  test "seed matches the questionnaire source data exactly" do
    load Rails.root.join("db/seeds.rb")

    assessment = Assessment.find_by!(title: "Diagnostic Langues & Métiers")
    questions = assessment.diagnostic_questions.active

    assert_equal 16, questions.interest.count
    assert_equal 16, questions.disc.count
    assert_equal 12, questions.competence.count

    filiere_tally = questions.interest.pluck(:filiere_slug).tally
    assert_equal FILIERES.map { |f| f["filiere_slug"] }.sort, filiere_tally.keys.sort
    assert filiere_tally.values.all? { |count| count == 2 }, "Each filière should have exactly 2 questions"

    careers = Career.diagnostic.published
    assert_equal 37, careers.count
    assert careers.exists?(title: "Guide touristique")
    assert_not careers.exists?(title: "Guide touristique / patrimonial")
    assert_equal %w[gestion_projet numerique gestion_projet],
      careers.find_by!(title: "Chef de projet e-learning").required_competences
    assert_equal ["Langues étrangères", "Communication écrite", "Communication orale", "Analyse de données",
      "Gestion de projet", "Compétences numériques", "Négociation", "Créativité", "Écoute active",
      "Rigueur et méthode", "Culture générale", "Droit et politiques publiques"],
      questions.competence.ordered.map { |question| question.options.dig(0, "label") }
  end
end
