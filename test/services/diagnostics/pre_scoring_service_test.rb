require "test_helper"

class Diagnostics::PreScoringServiceTest < ActiveSupport::TestCase
  def setup
    AcademicField.find_or_create_by!(slug: "langues") { |field| field.name = "Langues"; field.position = 1 }
    Skill.find_or_create_by!(slug: "langues_etrangeres") { |skill| skill.name = "Langues étrangères"; skill.position = 1 }

    @user       = User.create!(email: "score#{SecureRandom.hex(4)}@test.com", password: "password123",
                                first_name: "Score", last_name: "Test", city: "Cotonou",
                                country: "BJ", diploma: "Licence", employment_status: "Étudiant")
    @assessment = Assessment.create!(title: "Scoring Test #{SecureRandom.hex(4)}", active: false)
    @diagnostic = Diagnostic.create!(user: @user, assessment: @assessment, status: :in_progress)

    # 1 interest question → langues
    @iq = @assessment.diagnostic_questions.create!(
      kind: :interest, text: "Les langues m'attirent.",
      academic_field_slug: "langues",
      position: 1
    )
    # 1 disc question (D type)
    @dq = @assessment.diagnostic_questions.create!(
      kind: :disc, text: "Je décide vite.", disc_type: "D", position: 2
    )
    # 1 skill question
    @cq = @assessment.diagnostic_questions.create!(
      kind: :skill, text: "Je parle une langue.", skill_slug: "langues_etrangeres", position: 3
    )

    # Seed answers
    @diagnostic.diagnostic_answers.create!(diagnostic_question: @iq, dimension_slug: "langues", answer_value: "4", points_awarded: 4)
    @diagnostic.diagnostic_answers.create!(diagnostic_question: @dq, dimension_slug: "D", answer_value: "4", points_awarded: 4)
    @diagnostic.diagnostic_answers.create!(diagnostic_question: @cq, dimension_slug: "langues_etrangeres", answer_value: "5", points_awarded: 5)

    # A career that should score well
    hex = SecureRandom.hex(4)
    @career = Career.create!(
      title: "Traducteur #{hex}", status: :published, academic_field_slug: "langues",
      disc_types: [ "C", "D" ], required_skills: [ "langues_etrangeres" ]
    )
  end

  test "stores disc_scores in score_data" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert_equal 4, @diagnostic.score_data["disc_scores"]["D"]
  end

  test "stores academic_field_scores in score_data" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert_equal 4, @diagnostic.score_data["academic_field_scores"]["langues"]
  end

  test "academic_field_scores accumulates points_awarded across multiple interest answers" do
    iq2 = @assessment.diagnostic_questions.create!(
      kind: :interest, text: "La traduction m'attire.",
      academic_field_slug: "langues",
      position: 100
    )
    @diagnostic.diagnostic_answers.create!(
      diagnostic_question: iq2, dimension_slug: "langues",
      answer_value: "3", points_awarded: 3
    )

    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert_equal 7, @diagnostic.score_data["academic_field_scores"]["langues"]
  end

  test "stores skill_scores in score_data" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert_equal 5, @diagnostic.score_data["skill_scores"]["langues_etrangeres"]
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

  test "stores dominant_disc_types and dominant_academic_field in score_data" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert_equal [ "D" ], @diagnostic.score_data["dominant_disc_types"]
    assert_equal "langues", @diagnostic.score_data["dominant_academic_field"]
  end

  test "stores per-career match breakdown in top_career_ids" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    entry = @diagnostic.score_data["top_career_ids"].find { |h| h["id"] == @career.id }
    assert_equal 3, entry["disc_match"]
    assert_equal 5, entry["academic_field_match"]
    assert_equal 5, entry["comp_match"]
    assert_equal [ "D" ], entry["matched_disc_types"]
    assert_equal({ "langues_etrangeres" => 5 }, entry["matched_skills"])
  end

  test "matched_skills omits required skills the user never answered" do
    hex = SecureRandom.hex(4)
    unanswered_skill_career = Career.create!(
      title: "Guide #{hex}", status: :published, academic_field_slug: "langues",
      disc_types: [], required_skills: [ "langues_etrangeres", "numerique" ]
    )

    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    entry = @diagnostic.score_data["top_career_ids"].find { |h| h["id"] == unanswered_skill_career.id }
    assert_equal({ "langues_etrangeres" => 5 }, entry["matched_skills"])
  end
end
