require "test_helper"

class Diagnostics::AnswerAttributionPresenterTest < ActiveSupport::TestCase
  def setup
    @user       = User.create!(email: "attr#{SecureRandom.hex(4)}@test.com", password: "password123",
                                first_name: "Attr", last_name: "Test", city: "Cotonou",
                                country: "BJ", diploma: "Licence", employment_status: "Étudiant")
    @assessment = Assessment.create!(title: "Attribution Test #{SecureRandom.hex(4)}", active: false)
    @diagnostic = Diagnostic.create!(user: @user, assessment: @assessment, status: :completed)

    @disc_question     = @assessment.diagnostic_questions.create!(kind: :disc, text: "Je décide vite.", disc_type: "D", position: 1)
    @interest_question = @assessment.diagnostic_questions.create!(kind: :interest, text: "Les langues m'attirent.", academic_field_slug: "langues", position: 2)

    @disc_answer     = @diagnostic.diagnostic_answers.create!(diagnostic_question: @disc_question, dimension_slug: "D", answer_value: "4", points_awarded: 4, effective_value: 4)
    @interest_answer = @diagnostic.diagnostic_answers.create!(diagnostic_question: @interest_question, dimension_slug: "langues", answer_value: "4", points_awarded: 4, effective_value: 4)

    @primary   = Career.create!(title: "Traducteur #{SecureRandom.hex(4)}", status: :published,
                                 academic_field_slug: "langues", disc_types: [ "D" ], required_skills: [ "langues_etrangeres" ],
                                 affirmations: [ "Ça me ressemble." ])
    @secondary = Career.create!(title: "Interprète #{SecureRandom.hex(4)}", status: :published,
                                 academic_field_slug: "geo", disc_types: [], required_skills: [])

    @diagnostic.diagnostic_answers.create!(career: @primary, affirmation_index: 0, affirmation_text: "Ça me ressemble.",
                                            answer_value: "5", points_awarded: 5, effective_value: 5)

    @diagnostic.update!(
      primary_career:       @primary,
      complementary_career: @secondary,
      score_data: {
        "dominant_academic_fields" => [ "langues", "geo" ],
        "dominant_disc_types"      => [ "D", "I" ],
        "retained_careers" => [
          {
            "career_id" => @primary.id, "academic_field_slug" => "langues", "academic_field_score" => 90.0,
            "matched_disc_types" => [ "D" ], "disc_match_count" => 1, "fallback" => false,
            "skill_score" => 100.0, "missing_required_skills" => false, "affirmation_score" => 100.0, "final_score" => 100.0
          },
          {
            "career_id" => @secondary.id, "academic_field_slug" => "geo", "academic_field_score" => 60.0,
            "matched_disc_types" => [], "disc_match_count" => 0, "fallback" => true,
            "skill_score" => 0.0, "missing_required_skills" => true, "affirmation_score" => 0.0, "final_score" => 0.0
          }
        ]
      }
    )

    @presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)
  end

  test "badges the DISC answer for the career whose matched_disc_types include it" do
    badge = @presenter.badges_for(@disc_answer).sole
    assert_equal "Métier 1", badge[:label]
    assert_equal "Type DISC Dominant retenu", badge[:text]
  end

  test "badges the interest answer for the career matching one of the 2 dominant fields" do
    badge = @presenter.badges_for(@interest_answer).sole
    assert_equal "Métier 1", badge[:label]
    assert_equal "Filière dominante retenue (Langues)", badge[:text]
  end

  test "does not badge an answer for a career it doesn't match" do
    labels = @presenter.badges_for(@disc_answer).map { |b| b[:label] }
    assert_not_includes labels, "Métier 2"
  end

  test "exposes an explicit contribution rule for each answer" do
    disc_detail = @presenter.contribution_details_for(@disc_answer).sole
    assert_equal :flat_bonus, disc_detail[:contribution_type]
    assert_equal "Filtre de personnalité", disc_detail[:rule]
  end

  test "labels Likert answers for the audit view" do
    assert_equal "Plutôt moi", @presenter.answer_value_label(@disc_answer)
    assert_equal "Profil de travail", @presenter.question_kind_label(@disc_question)
  end

  test "affirmation_rows lists each recorded affirmation rating with its career label" do
    rows = @presenter.affirmation_rows
    assert_equal 1, rows.size
    assert_equal "Métier 1", rows.first[:label]
    assert_equal @primary.id, rows.first[:career_id]
    assert_includes rows.first[:text], "Ça me ressemble."
    assert_includes rows.first[:text], "5/5"
  end

  test "is unavailable when score_data lacks scored retained_careers (legacy or in-progress diagnostic)" do
    @diagnostic.update!(score_data: { "retained_careers" => [ { "career_id" => @primary.id } ] })
    presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)

    assert_not presenter.available?
    assert_empty presenter.badges_for(@disc_answer)
    assert_empty presenter.affirmation_rows
  end

  test "overview_cards has exactly 2 retained entries, never a 3rd candidate" do
    labels = @presenter.overview_cards.map { |c| c[:label] }
    assert_equal [ "Métier 1", "Métier 2" ], labels
    assert @presenter.overview_cards.all? { |c| c[:retained] }
    assert @presenter.overview_cards.all? { |c| c[:has_affirmation_data] }
  end

  test "overview_cards total matches final_score" do
    card = @presenter.overview_cards.first
    assert_equal 100.0, card[:total]
  end

  test "category_breakdown reports the filière académique, DISC, compétences, and affirmations rows" do
    card = @presenter.overview_cards.first
    labels = card[:categories].map { |c| c[:label] }
    assert_equal [ "Filière académique", "Personnalité (DISC)", "Compétences", "Affirmations" ], labels

    disc_row = card[:categories].find { |c| c[:label] == "Personnalité (DISC)" }
    assert_equal({ label: "Personnalité (DISC)", points: 1, max: 2 }, disc_row)
  end
end
