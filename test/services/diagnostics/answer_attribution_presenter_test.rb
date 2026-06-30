require "test_helper"

class Diagnostics::AnswerAttributionPresenterTest < ActiveSupport::TestCase
  def setup
    @user       = User.create!(email: "attr#{SecureRandom.hex(4)}@test.com", password: "password123",
                                first_name: "Attr", last_name: "Test", city: "Cotonou",
                                country: "BJ", diploma: "Licence", employment_status: "Étudiant")
    @assessment = Assessment.create!(title: "Attribution Test #{SecureRandom.hex(4)}", active: false)
    @diagnostic = Diagnostic.create!(user: @user, assessment: @assessment, status: :completed)

    @disc_question      = @assessment.diagnostic_questions.create!(kind: :disc, text: "Je décide vite.", disc_type: "D", position: 1)
    @interest_question  = @assessment.diagnostic_questions.create!(kind: :interest, text: "Les langues m'attirent.", academic_field_slug: "langues", position: 2)
    @skill_question     = @assessment.diagnostic_questions.create!(kind: :skill, text: "Je parle une langue.", skill_slug: "langues_etrangeres", position: 3)

    @disc_answer     = @diagnostic.diagnostic_answers.create!(diagnostic_question: @disc_question, dimension_slug: "D", answer_value: "4", points_awarded: 4)
    @interest_answer = @diagnostic.diagnostic_answers.create!(diagnostic_question: @interest_question, dimension_slug: "langues", answer_value: "4", points_awarded: 4)
    @skill_answer    = @diagnostic.diagnostic_answers.create!(diagnostic_question: @skill_question, dimension_slug: "langues_etrangeres", answer_value: "5", points_awarded: 5)

    @primary   = Career.create!(title: "Traducteur #{SecureRandom.hex(4)}", status: :published,
                                 academic_field_slug: "langues", disc_types: [ "D" ], required_skills: [ "langues_etrangeres" ],
                                 affirmations: %w[a b c])
    @secondary = Career.create!(title: "Interprète #{SecureRandom.hex(4)}", status: :published,
                                 academic_field_slug: "geo", disc_types: [ "I" ], required_skills: [])

    @diagnostic.update!(
      primary_career:       @primary,
      complementary_career: @secondary,
      score_data: {
        "disc_scores"             => { "D" => 4 },
        "academic_field_scores"   => { "langues" => 4 },
        "skill_scores"            => { "langues_etrangeres" => 5 },
        "dominant_disc_types"     => [ "D" ],
        "dominant_academic_field" => "langues",
        "top_career_ids" => [
          {
            "id" => @primary.id, "score" => 13,
            "disc_match" => 3, "academic_field_match" => 5, "comp_match" => 5,
            "matched_disc_types" => [ "D" ], "matched_skills" => { "langues_etrangeres" => 5 }
          },
          {
            "id" => @secondary.id, "score" => 0,
            "disc_match" => 0, "academic_field_match" => 0, "comp_match" => 0,
            "matched_disc_types" => [], "matched_skills" => {}
          }
        ],
        "affirmation_breakdown" => {
          @primary.id.to_s => { "checked_affirmations" => %w[a b], "bonus" => 2, "max_bonus" => 3 }
        }
      }
    )

    @presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)
  end

  test "badges the DISC answer for the career whose matched_disc_types include it" do
    assert_equal [ { label: "Métier 1", points: 3 } ], @presenter.badges_for(@disc_answer)
  end

  test "badges the interest answer for the career matching the dominant academic field" do
    assert_equal [ { label: "Métier 1", points: 5 } ], @presenter.badges_for(@interest_answer)
  end

  test "badges the skill answer with the actual points for a career requiring that skill" do
    assert_equal [ { label: "Métier 1", points: 5 } ], @presenter.badges_for(@skill_answer)
  end

  test "does not badge an answer for a career it doesn't match" do
    labels = @presenter.badges_for(@disc_answer).map { |b| b[:label] }
    assert_not_includes labels, "Métier 2"
  end

  test "recap_line shows each career's final score including affirmation bonus" do
    assert_equal "Métier 1 : 15 pts · Métier 2 : 0 pts", @presenter.recap_line
  end

  test "affirmation_rows lists each checked affirmation with its career label" do
    assert_equal [
      { label: "Métier 1", text: "a" },
      { label: "Métier 1", text: "b" }
    ], @presenter.affirmation_rows
  end

  test "is unavailable when score_data lacks the match breakdown (legacy diagnostic)" do
    @diagnostic.update!(score_data: {
      "top_career_ids" => [ { "id" => @primary.id, "score" => 13 }, { "id" => @secondary.id, "score" => 9 } ]
    })
    presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)

    assert_not presenter.available?
    assert_empty presenter.badges_for(@disc_answer)
    assert_nil presenter.recap_line
    assert_empty presenter.affirmation_rows
  end
end
