# test/services/diagnostics/scoring_service_test.rb
require "test_helper"

class Diagnostics::ScoringServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "scorer#{SecureRandom.hex(4)}@test.com", password: "password123", first_name: "Test", last_name: "User", city: "Test City", country: "CI", diploma: "Master", employment_status: "En emploi")
    @d    = Diagnostic.create!(user: @user, status: :in_progress)

    @p_analytique    = Career.create!(title: "Analyste",      slug: "analyste-#{SecureRandom.hex(3)}", status: :published, kind: :behavioral)
    @p_coordinateur  = Career.create!(title: "Coordinateur",  slug: "coordo-#{SecureRandom.hex(3)}", status: :published, kind: :behavioral)
    @p_digital       = Career.create!(title: "Digital",       slug: "digital-#{SecureRandom.hex(3)}", status: :published, kind: :behavioral)

    @q_bloc1 = AssessmentQuestion.create!(bloc: 1, text: "Q1", kind: "mcq", position: 1, scored: true,
      options: [
        { "value" => "A", "profile_slug" => @p_analytique.slug,   "points" => 1 },
        { "value" => "B", "profile_slug" => @p_digital.slug,      "points" => 1 }
      ])
    @q_bloc2 = AssessmentQuestion.create!(bloc: 2, text: "Q2", kind: "mcq", position: 1, scored: true,
      options: [
        { "value" => "A", "profile_slug" => @p_analytique.slug,   "points" => 1 },
        { "value" => "B", "profile_slug" => @p_coordinateur.slug, "points" => 1 }
      ])
    @q_interp = AssessmentQuestion.create!(bloc: 4, text: "Q3", kind: "mcq", position: 1, scored: false,
      options: [ { "value" => "A", "profile_slug" => nil, "points" => 0 } ])
  end

  test "sets primary profile to highest-scoring dimension" do
    answer(@q_bloc1, "A", @p_analytique.slug, 1)
    answer(@q_bloc2, "A", @p_analytique.slug, 1)

    Diagnostics::ScoringService.call(@d)
    @d.reload

    assert_equal @p_analytique.id, @d.primary_career_id
    assert_equal 2, @d.score_data[@p_analytique.slug]
  end

  test "sets complementary to second-highest" do
    answer(@q_bloc1, "A", @p_analytique.slug, 1)
    answer(@q_bloc2, "B", @p_coordinateur.slug, 1)

    q3 = AssessmentQuestion.create!(bloc: 1, text: "Q3", kind: "mcq", position: 2, scored: true,
      options: [ { "value" => "A", "profile_slug" => @p_analytique.slug, "points" => 1 } ])
    answer(q3, "A", @p_analytique.slug, 1)

    Diagnostics::ScoringService.call(@d)
    @d.reload

    assert_equal @p_analytique.id,   @d.primary_career_id
    assert_equal @p_coordinateur.id, @d.complementary_career_id
  end

  test "tiebreak favors bloc 2 profile" do
    answer(@q_bloc1, "A", @p_analytique.slug,   1)  # bloc 1 → analytique
    answer(@q_bloc2, "B", @p_coordinateur.slug,  1)  # bloc 2 → coordinateur
    # tied at 1-1; bloc 2 winner = coordinateur

    Diagnostics::ScoringService.call(@d)
    @d.reload

    assert_equal @p_coordinateur.id, @d.primary_career_id
  end

  test "marks diagnostic as completed" do
    Diagnostics::ScoringService.call(@d)
    assert @d.reload.pending_payment?
  end

  test "ignores unscored answers" do
    answer(@q_interp, "A", nil, 0)
    Diagnostics::ScoringService.call(@d)
    assert @d.reload.pending_payment?  # no crash, graceful
  end

  private

  def answer(assessment_question, value, dimension, points)
    DiagnosticAnswer.create!(
      diagnostic: @d, assessment_question: assessment_question,
      answer_value: value, profile_dimension: dimension, points_awarded: points
    )
  end
end
