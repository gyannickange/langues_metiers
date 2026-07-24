require "test_helper"

class Diagnostics::PreScoringServiceTest < ActiveSupport::TestCase
  def setup
    AcademicField.find_or_create_by!(slug: "langues") { |f| f.name = "Langues"; f.position = 1 }
    AcademicField.find_or_create_by!(slug: "geo")     { |f| f.name = "Géographie"; f.position = 2 }

    @user       = User.create!(email: "score#{SecureRandom.hex(4)}@test.com", password: "password123",
                                first_name: "Score", last_name: "Test", city: "Cotonou",
                                country: "BJ", diploma: "Licence", employment_status: "Étudiant")
    @assessment = Assessment.create!(title: "Scoring Test #{SecureRandom.hex(4)}", active: false)
    @diagnostic = Diagnostic.create!(user: @user, assessment: @assessment, status: :in_progress)

    # 2 interest questions on langues (avg 4.5), 1 on geo (avg 2) -> langues and geo are the 2 dominant fields (only 2 exist)
    langues_q1 = @assessment.diagnostic_questions.create!(kind: :interest, text: "Q1", academic_field_slug: "langues", position: 1)
    langues_q2 = @assessment.diagnostic_questions.create!(kind: :interest, text: "Q2", academic_field_slug: "langues", position: 2)
    geo_q1     = @assessment.diagnostic_questions.create!(kind: :interest, text: "Q3", academic_field_slug: "geo", position: 3)
    @diagnostic.diagnostic_answers.create!(diagnostic_question: langues_q1, dimension_slug: "langues", answer_value: "5", points_awarded: 5, effective_value: 5)
    @diagnostic.diagnostic_answers.create!(diagnostic_question: langues_q2, dimension_slug: "langues", answer_value: "4", points_awarded: 4, effective_value: 4)
    @diagnostic.diagnostic_answers.create!(diagnostic_question: geo_q1, dimension_slug: "geo", answer_value: "2", points_awarded: 2, effective_value: 2)

    # 2 disc questions: D avg 5, I avg 3 -> D and I are the 2 dominant types
    d_q = @assessment.diagnostic_questions.create!(kind: :disc, text: "Q4", disc_type: "D", position: 4)
    i_q = @assessment.diagnostic_questions.create!(kind: :disc, text: "Q5", disc_type: "I", position: 5)
    @diagnostic.diagnostic_answers.create!(diagnostic_question: d_q, dimension_slug: "D", answer_value: "5", points_awarded: 5, effective_value: 5)
    @diagnostic.diagnostic_answers.create!(diagnostic_question: i_q, dimension_slug: "I", answer_value: "3", points_awarded: 3, effective_value: 3)

    @matching_career = Career.create!(
      title: "Traducteur #{SecureRandom.hex(4)}", status: :published,
      academic_field_slug: "langues", disc_types: [ "D", "S" ]
    )
    @non_matching_disc_career = Career.create!(
      title: "Guide #{SecureRandom.hex(4)}", status: :published,
      academic_field_slug: "langues", disc_types: [ "C" ]
    )
    @geo_career = Career.create!(
      title: "Géographe #{SecureRandom.hex(4)}", status: :published,
      academic_field_slug: "geo", disc_types: [ "I" ]
    )
  end

  test "stores normalized academic_field_scores as an average, not a sum" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert_equal 87.5, @diagnostic.score_data["academic_field_scores"]["langues"] # avg 4.5 -> normalized: ((4.5-1)/4)*100 = 87.5
  end

  test "stores dominant_academic_fields as the top 2 fields" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert_equal [ "langues", "geo" ], @diagnostic.score_data["dominant_academic_fields"]
  end

  test "stores dominant_disc_types as the top 2 types" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert_equal [ "D", "I" ], @diagnostic.score_data["dominant_disc_types"]
  end

  test "retained_careers excludes careers whose disc_types don't match, when enough matches exist" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    retained_ids = @diagnostic.score_data["retained_careers"].map { |e| e["career_id"] }
    assert_includes retained_ids, @matching_career.id
    assert_includes retained_ids, @geo_career.id
    assert_not_includes retained_ids, @non_matching_disc_career.id
  end

  test "retained_careers always has exactly 2 entries" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert_equal 2, @diagnostic.score_data["retained_careers"].size
  end

  test "retained_careers records disc_match_count and matched_disc_types" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    entry = @diagnostic.score_data["retained_careers"].find { |e| e["career_id"] == @matching_career.id }
    assert_equal 1, entry["disc_match_count"]
    assert_equal [ "D" ], entry["matched_disc_types"]
    assert_equal false, entry["fallback"]
  end

  test "falls back to the best-ranked Pool A careers, flagged fallback: true, when the DISC filter leaves fewer than 2" do
    @non_matching_disc_career.update!(disc_types: [])
    @geo_career.destroy!
    filler = Career.create!(title: "Filler #{SecureRandom.hex(4)}", status: :published, academic_field_slug: "langues", disc_types: [])

    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload

    entries = @diagnostic.score_data["retained_careers"]
    assert_equal 2, entries.size
    assert_includes entries.map { |e| e["career_id"] }, @matching_career.id
    fallback_entry = entries.find { |e| e["career_id"] != @matching_career.id }
    assert_equal true, fallback_entry["fallback"]
    assert_includes [ @non_matching_disc_career.id, filler.id ], fallback_entry["career_id"]
  end

  test "raises InsufficientCareersError when Pool A has fewer than 2 careers" do
    Career.destroy_all

    assert_raises Diagnostics::PreScoringService::InsufficientCareersError do
      Diagnostics::PreScoringService.call(@diagnostic)
    end
    assert_equal({}, @diagnostic.reload.score_data)
  end

  test "falls back to computing the effective_value from points_awarded and reverse_scored when the column is nil" do
    reversed_q = @assessment.diagnostic_questions.create!(
      kind: :interest, text: "Je n'aime pas les langues.", academic_field_slug: "langues", position: 6, reverse_scored: true
    )
    # effective_value left nil on purpose, simulating a legacy row the backfill didn't reach
    @diagnostic.diagnostic_answers.create!(diagnostic_question: reversed_q, dimension_slug: "langues", answer_value: "2", points_awarded: 2, effective_value: nil)

    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload

    # langues effective values are now [5, 4, 6-2=4] -> average (13/3) -> normalize
    expected = Diagnostics::LikertScoring.normalize(Diagnostics::LikertScoring.average([ 5, 4, 4 ])).round(2)
    assert_equal expected, @diagnostic.score_data["academic_field_scores"]["langues"]
  end

  test "does not change diagnostic status" do
    Diagnostics::PreScoringService.call(@diagnostic)
    @diagnostic.reload
    assert @diagnostic.in_progress?
  end
end
