require "test_helper"

class Diagnostics::ResultsPresenterTest < ActiveSupport::TestCase
  def setup
    AcademicField.find_or_create_by!(slug: "langues") { |f| f.name = "Langues"; f.position = 1 }
    AcademicField.find_or_create_by!(slug: "geo")     { |f| f.name = "Géographie"; f.position = 2 }

    @user       = User.create!(email: "results#{SecureRandom.hex(4)}@test.com", password: "password123",
                                first_name: "Results", last_name: "Test", city: "Cotonou",
                                country: "BJ", diploma: "Licence", employment_status: "Étudiant")
    @assessment = Assessment.create!(title: "Results Test #{SecureRandom.hex(4)}", active: false)
    @career     = Career.create!(title: "Traducteur #{SecureRandom.hex(4)}", status: :published, required_skills: [])
    @diagnostic = Diagnostic.create!(user: @user, assessment: @assessment, status: :completed, primary_career: @career)
  end

  test "score_explanation_available? is false for the old score_data shape (top_career_ids/disc_match)" do
    @diagnostic.update!(score_data: {
      "dominant_academic_field" => "langues",
      "top_career_ids" => [ { "id" => @career.id, "score" => 5, "disc_match" => 0 } ]
    })

    assert_not Diagnostics::ResultsPresenter.new(@diagnostic).score_explanation_available?
  end

  test "score_explanation_available? is true for the new retained_careers shape" do
    @diagnostic.update!(score_data: {
      "dominant_academic_fields" => [ "langues", "geo" ],
      "retained_careers" => [ { "career_id" => @career.id, "final_score" => 80.0 } ]
    })

    assert Diagnostics::ResultsPresenter.new(@diagnostic).score_explanation_available?
  end

  test "explanation_factors builds the interest sentence from dominant_academic_fields (plural)" do
    @diagnostic.update!(score_data: { "dominant_academic_fields" => [ "langues", "geo" ] })

    factor = Diagnostics::ResultsPresenter.new(@diagnostic).explanation_factors.find { |f| f[:key] == :interest }

    assert_equal "Votre intérêt pour Langues et Géographie & territoires a orienté la sélection des métiers proposés.", factor[:text]
  end

  test "explanation_factors omits the interest factor when dominant_academic_fields is absent (old shape)" do
    @diagnostic.update!(score_data: { "dominant_academic_field" => "langues" })

    factor = Diagnostics::ResultsPresenter.new(@diagnostic).explanation_factors.find { |f| f[:key] == :interest }

    assert_nil factor
  end

  test "explanation_factors includes the affirmations factor when career-affirmation answers exist for the primary career" do
    @diagnostic.diagnostic_answers.create!(career: @career, affirmation_index: 0, affirmation_text: "Ça me ressemble.",
                                            answer_value: "5", points_awarded: 5, effective_value: 5)

    factor = Diagnostics::ResultsPresenter.new(@diagnostic).explanation_factors.find { |f| f[:key] == :affirmations }

    assert factor.present?
  end

  test "explanation_factors omits the affirmations factor when no affirmation answers exist" do
    factor = Diagnostics::ResultsPresenter.new(@diagnostic).explanation_factors.find { |f| f[:key] == :affirmations }

    assert_nil factor
  end
end
