require "test_helper"

class Diagnostics::ScoringServiceTest < ActiveSupport::TestCase
  def setup
    @user       = User.create!(email: "final#{SecureRandom.hex(4)}@test.com", password: "password123",
                                first_name: "Final", last_name: "Test", city: "Cotonou",
                                country: "BJ", diploma: "Licence", employment_status: "Étudiant")
    @assessment = Assessment.create!(title: "Final Score Test #{SecureRandom.hex(4)}", active: false)

    @c1 = Career.create!(title: "Métier 1 #{SecureRandom.hex(4)}", status: :published, academic_field_slug: "langues",
                          required_skills: %w[langues_etrangeres numerique], affirmations: %w[a b])
    @c2 = Career.create!(title: "Métier 2 #{SecureRandom.hex(4)}", status: :published, academic_field_slug: "langues",
                          required_skills: [], affirmations: %w[c d])

    @diagnostic = Diagnostic.create!(
      user: @user, assessment: @assessment, status: :in_progress,
      selected_skills: [ "langues_etrangeres" ],
      score_data: {
        "retained_careers" => [
          { "career_id" => @c1.id, "academic_field_slug" => "langues", "academic_field_score" => 90.0, "matched_disc_types" => [ "D" ], "disc_match_count" => 1, "fallback" => false },
          { "career_id" => @c2.id, "academic_field_slug" => "langues", "academic_field_score" => 90.0, "matched_disc_types" => [], "disc_match_count" => 0, "fallback" => false }
        ]
      }
    )

    # c1: 1 of 2 required_skills selected -> skill_score 50; affirmations rated 5 and 5 -> affirmation_score 100
    @diagnostic.diagnostic_answers.create!(career: @c1, affirmation_index: 0, affirmation_text: "a", answer_value: "5", points_awarded: 5, effective_value: 5)
    @diagnostic.diagnostic_answers.create!(career: @c1, affirmation_index: 1, affirmation_text: "b", answer_value: "5", points_awarded: 5, effective_value: 5)
    # c2: no required_skills -> skill_score 0, missing_required_skills true; affirmations rated 3 and 3 -> affirmation_score 50
    @diagnostic.diagnostic_answers.create!(career: @c2, affirmation_index: 0, affirmation_text: "c", answer_value: "3", points_awarded: 3, effective_value: 3)
    @diagnostic.diagnostic_answers.create!(career: @c2, affirmation_index: 1, affirmation_text: "d", answer_value: "3", points_awarded: 3, effective_value: 3)
  end

  test "sets primary and complementary careers by final_score" do
    Diagnostics::ScoringService.call(@diagnostic)
    @diagnostic.reload
    assert_equal @c1, @diagnostic.primary_career
    assert_equal @c2, @diagnostic.complementary_career
  end

  test "computes skill_score as a percentage of matched required_skills" do
    Diagnostics::ScoringService.call(@diagnostic)
    entry = @diagnostic.reload.score_data["retained_careers"].find { |e| e["career_id"] == @c1.id }
    assert_equal 50.0, entry["skill_score"]
    assert_equal [ "langues_etrangeres" ], entry["selected_matching_skills"]
    assert_equal false, entry["missing_required_skills"]
  end

  test "scores a career with no required_skills as 0 and flags missing_required_skills" do
    Diagnostics::ScoringService.call(@diagnostic)
    entry = @diagnostic.reload.score_data["retained_careers"].find { |e| e["career_id"] == @c2.id }
    assert_equal 0.0, entry["skill_score"]
    assert_equal true, entry["missing_required_skills"]
  end

  test "computes affirmation_score as a normalized average of effective_value ratings" do
    Diagnostics::ScoringService.call(@diagnostic)
    entry = @diagnostic.reload.score_data["retained_careers"].find { |e| e["career_id"] == @c1.id }
    assert_equal 100.0, entry["affirmation_score"]
  end

  test "final_score weights skill_score at 40% and affirmation_score at 60%" do
    Diagnostics::ScoringService.call(@diagnostic)
    entry = @diagnostic.reload.score_data["retained_careers"].find { |e| e["career_id"] == @c1.id }
    assert_equal 80.0, entry["final_score"] # 0.4*50 + 0.6*100
  end

  test "sets status to pending_payment and completed_at" do
    Diagnostics::ScoringService.call(@diagnostic)
    @diagnostic.reload
    assert @diagnostic.pending_payment?
    assert_not_nil @diagnostic.completed_at
  end

  test "raises InsufficientCareersError when fewer than 2 retained careers are stored" do
    @diagnostic.update!(score_data: { "retained_careers" => [ { "career_id" => @c1.id } ] })

    assert_raises Diagnostics::ScoringService::InsufficientCareersError do
      Diagnostics::ScoringService.call(@diagnostic)
    end
    assert @diagnostic.reload.in_progress?
  end

  test "raises InsufficientCareersError when a retained career id no longer resolves" do
    @diagnostic.update!(score_data: {
      "retained_careers" => [
        { "career_id" => @c1.id, "academic_field_slug" => "langues", "academic_field_score" => 90.0, "matched_disc_types" => [], "disc_match_count" => 0 },
        { "career_id" => SecureRandom.uuid, "academic_field_slug" => "langues", "academic_field_score" => 90.0, "matched_disc_types" => [], "disc_match_count" => 0 }
      ]
    })

    assert_raises Diagnostics::ScoringService::InsufficientCareersError do
      Diagnostics::ScoringService.call(@diagnostic)
    end
  end

  test "breaks ties on career_id when final_score, affirmation_score, disc_match_count and academic_field_score are all equal" do
    tied = Career.create!(title: "Tied #{SecureRandom.hex(4)}", status: :published, academic_field_slug: "langues",
                           required_skills: [], affirmations: [])
    @diagnostic.update!(
      selected_skills: [],
      score_data: {
        "retained_careers" => [
          { "career_id" => @c1.id, "academic_field_slug" => "langues", "academic_field_score" => 50.0, "matched_disc_types" => [], "disc_match_count" => 0 },
          { "career_id" => tied.id, "academic_field_slug" => "langues", "academic_field_score" => 50.0, "matched_disc_types" => [], "disc_match_count" => 0 }
        ]
      }
    )
    @diagnostic.diagnostic_answers.destroy_all

    Diagnostics::ScoringService.call(@diagnostic)
    @diagnostic.reload
    # both careers score 0 everywhere; career_id is the final, deterministic tie-break
    expected_primary = [ @c1, tied ].min_by(&:id)
    assert_equal expected_primary, @diagnostic.primary_career
  end

  test "breaks a final_score/affirmation_score tie on disc_match_count" do
    # both careers: no required_skills (skill_score 0 for both) and no affirmations (affirmation_score 0 for
    # both) -> final_score ties at 0 for both. Only disc_match_count differs, so it must decide the winner.
    higher_disc = Career.create!(title: "Higher DISC #{SecureRandom.hex(4)}", status: :published,
                                  academic_field_slug: "langues", required_skills: [], affirmations: [])
    lower_disc  = Career.create!(title: "Lower DISC #{SecureRandom.hex(4)}", status: :published,
                                  academic_field_slug: "langues", required_skills: [], affirmations: [])
    @diagnostic.update!(
      selected_skills: [],
      score_data: {
        "retained_careers" => [
          { "career_id" => higher_disc.id, "academic_field_slug" => "langues", "academic_field_score" => 50.0, "matched_disc_types" => [ "D", "I" ], "disc_match_count" => 2 },
          { "career_id" => lower_disc.id,  "academic_field_slug" => "langues", "academic_field_score" => 50.0, "matched_disc_types" => [ "D" ],      "disc_match_count" => 1 }
        ]
      }
    )
    @diagnostic.diagnostic_answers.destroy_all

    Diagnostics::ScoringService.call(@diagnostic)
    @diagnostic.reload

    assert_equal higher_disc, @diagnostic.primary_career
    assert_equal lower_disc, @diagnostic.complementary_career
  end

  test "breaks a final_score/affirmation_score/disc_match_count tie on academic_field_score" do
    # same shape as above, but disc_match_count also ties (0 for both) -> academic_field_score must decide.
    higher_field = Career.create!(title: "Higher Field #{SecureRandom.hex(4)}", status: :published,
                                   academic_field_slug: "langues", required_skills: [], affirmations: [])
    lower_field  = Career.create!(title: "Lower Field #{SecureRandom.hex(4)}", status: :published,
                                   academic_field_slug: "langues", required_skills: [], affirmations: [])
    @diagnostic.update!(
      selected_skills: [],
      score_data: {
        "retained_careers" => [
          { "career_id" => higher_field.id, "academic_field_slug" => "langues", "academic_field_score" => 90.0, "matched_disc_types" => [], "disc_match_count" => 0 },
          { "career_id" => lower_field.id,  "academic_field_slug" => "langues", "academic_field_score" => 40.0, "matched_disc_types" => [], "disc_match_count" => 0 }
        ]
      }
    )
    @diagnostic.diagnostic_answers.destroy_all

    Diagnostics::ScoringService.call(@diagnostic)
    @diagnostic.reload

    assert_equal higher_field, @diagnostic.primary_career
    assert_equal lower_field, @diagnostic.complementary_career
  end
end
