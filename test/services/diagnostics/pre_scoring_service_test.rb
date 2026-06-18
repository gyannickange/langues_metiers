require "test_helper"

class Diagnostics::PreScoringServiceTest < ActiveSupport::TestCase
  def setup
    @user       = User.create!(email: "score#{SecureRandom.hex(4)}@test.com", password: "password123",
                                first_name: "Score", last_name: "Test", city: "Cotonou",
                                country: "BJ", diploma: "Licence", employment_status: "Étudiant")
    @assessment = Assessment.create!(title: "Scoring Test #{SecureRandom.hex(4)}", active: false)
    @diagnostic = Diagnostic.create!(user: @user, assessment: @assessment, status: :in_progress)

    # 1 interest question → langues
    @iq = @assessment.diagnostic_questions.create!(
      kind: :interest, text: "Les langues m'attirent.",
      filiere_slug: "langues",
      position: 1
    )
    # 1 disc question (D type)
    @dq = @assessment.diagnostic_questions.create!(
      kind: :disc, text: "Je décide vite.", disc_type: "D", position: 2
    )
    # 1 competence question
    @cq = @assessment.diagnostic_questions.create!(
      kind: :competence, text: "Je parle une langue.", competence_slug: "langues_etrangeres", position: 3
    )

    # Seed answers
    @diagnostic.diagnostic_answers.create!(diagnostic_question: @iq, dimension_slug: "langues", answer_value: "4", points_awarded: 4)
    @diagnostic.diagnostic_answers.create!(diagnostic_question: @dq, dimension_slug: "D", answer_value: "4", points_awarded: 4)
    @diagnostic.diagnostic_answers.create!(diagnostic_question: @cq, dimension_slug: "langues_etrangeres", answer_value: "5", points_awarded: 5)

    # A career that should score well
    hex = SecureRandom.hex(4)
    @career = Career.create!(
      title: "Traducteur #{hex}", slug: "traducteur-#{hex}", status: :published, filiere_slug: "langues",
      disc_types: [ "C", "D" ], required_competences: [ "langues_etrangeres" ]
    )
  end

  test "stores disc_scores in score_data" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert_equal 4, @diagnostic.score_data["disc_scores"]["D"]
  end

  test "stores filiere_scores in score_data" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert_equal 4, @diagnostic.score_data["filiere_scores"]["langues"]
  end

  test "filiere_scores accumulates points_awarded across multiple interest answers" do
    iq2 = @assessment.diagnostic_questions.create!(
      kind: :interest, text: "La traduction m'attire.",
      filiere_slug: "langues",
      position: 100
    )
    @diagnostic.diagnostic_answers.create!(
      diagnostic_question: iq2, dimension_slug: "langues",
      answer_value: "3", points_awarded: 3
    )

    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert_equal 7, @diagnostic.score_data["filiere_scores"]["langues"]
  end

  test "stores competence_scores in score_data" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert_equal 5, @diagnostic.score_data["competence_scores"]["langues_etrangeres"]
  end

  test "stores top_career_ids in score_data" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert @diagnostic.score_data["top_career_ids"].is_a?(Array)
    assert @diagnostic.score_data["top_career_ids"].any? { |h| h["id"] == @career.id }
  end

  test "does not change diagnostic status" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert @diagnostic.in_progress?
  end
end
