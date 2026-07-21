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
    assert_empty presenter.affirmation_rows
  end

  test "overview_cards includes the 3rd-ranked candidate as a non-retained attribution" do
    third = Career.create!(title: "Guide touristique #{SecureRandom.hex(4)}", status: :published,
                            academic_field_slug: "histoire", disc_types: [ "S" ], required_skills: [])
    @diagnostic.score_data["top_career_ids"] << {
      "id" => third.id, "score" => 6,
      "disc_match" => 0, "academic_field_match" => 0, "comp_match" => 6,
      "matched_disc_types" => [], "matched_skills" => { "guidage" => 6 }
    }
    @diagnostic.save!
    presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)

    labels = presenter.overview_cards.map { |c| c[:label] }
    assert_equal [ "Métier 1", "Métier 2", "Non retenu" ], labels

    third_card = presenter.overview_cards.last
    assert_equal third, third_card[:career]
    assert_equal 6, third_card[:total]
    assert_equal false, third_card[:has_affirmation_data]
    assert_equal false, third_card[:retained]
    assert presenter.overview_cards.first(2).all? { |c| c[:retained] }
  end

  test "overview_cards omits the 3rd candidate when only 2 candidates exist" do
    presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)

    assert_equal [ "Métier 1", "Métier 2" ], presenter.overview_cards.map { |c| c[:label] }
  end

  test "overview_cards omits the 3rd candidate when it lacks breakdown data" do
    third = Career.create!(title: "Guide touristique #{SecureRandom.hex(4)}", status: :published,
                            academic_field_slug: "histoire", disc_types: [], required_skills: [])
    @diagnostic.score_data["top_career_ids"] << { "id" => third.id, "score" => 6 }
    @diagnostic.save!
    presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)

    assert_equal [ "Métier 1", "Métier 2" ], presenter.overview_cards.map { |c| c[:label] }
  end

  test "category_breakdown reports DISC max as the number of dominant DISC types times 3" do
    presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)
    primary_card = presenter.overview_cards.first

    disc_row = primary_card[:categories].find { |c| c[:label] == "DISC" }
    assert_equal({ label: "DISC", points: 3, max: 3 }, disc_row)
  end

  test "category_breakdown reports Intérêts with a fixed max of 5" do
    presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)
    primary_card = presenter.overview_cards.first

    interest_row = primary_card[:categories].find { |c| c[:label] == "Intérêts" }
    assert_equal({ label: "Intérêts", points: 5, max: 5 }, interest_row)
  end

  test "category_breakdown reports Compétences with no max" do
    presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)
    primary_card = presenter.overview_cards.first

    skill_row = primary_card[:categories].find { |c| c[:label] == "Compétences" }
    assert_equal({ label: "Compétences", points: 5, max: nil }, skill_row)
  end

  test "category_breakdown includes the affirmation bonus row only when affirmation data exists" do
    presenter = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)
    primary_card, secondary_card = presenter.overview_cards

    assert primary_card[:categories].any? { |c| c[:label] == "Bonus affirmations" }
    assert_equal({ label: "Bonus affirmations", points: 2, max: 3 },
                 primary_card[:categories].find { |c| c[:label] == "Bonus affirmations" })
    assert_not secondary_card[:categories].any? { |c| c[:label] == "Bonus affirmations" }
  end
end
