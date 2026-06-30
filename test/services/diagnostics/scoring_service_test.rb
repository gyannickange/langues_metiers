require "test_helper"

class Diagnostics::ScoringServiceTest < ActiveSupport::TestCase
  def setup
    @user       = User.create!(email: "final#{SecureRandom.hex(4)}@test.com", password: "password123",
                                first_name: "Final", last_name: "Test", city: "Cotonou",
                                country: "BJ", diploma: "Licence", employment_status: "Étudiant")
    @assessment = Assessment.create!(title: "Final Score Test #{SecureRandom.hex(4)}", active: false)
    @diagnostic = Diagnostic.create!(user: @user, assessment: @assessment, status: :in_progress)

    @c1 = Career.create!(title: "Métier 1 #{SecureRandom.hex(4)}", status: :published, academic_field_slug: "langues", disc_types: [ "C" ], required_skills: [])
    @c2 = Career.create!(title: "Métier 2 #{SecureRandom.hex(4)}", status: :published, academic_field_slug: "socio",   disc_types: [ "I" ], required_skills: [], affirmations: %w[a b c d e f])
    @c3 = Career.create!(title: "Métier 3 #{SecureRandom.hex(4)}", status: :published, academic_field_slug: "lettres", disc_types: [ "S" ], required_skills: [])

    @diagnostic.update!(score_data: {
      "disc_scores"       => { "C" => 18 },
      "academic_field_scores"    => { "langues" => 3 },
      "skill_scores" => {},
      "top_career_ids"    => [
        { "id" => @c1.id, "score" => 20 },
        { "id" => @c2.id, "score" => 15 },
        { "id" => @c3.id, "score" => 10 }
      ]
    })
  end

  test "sets primary and complementary careers" do
    Diagnostics::ScoringService.call(@diagnostic, {})
    @diagnostic.reload
    assert_equal @c1, @diagnostic.primary_career
    assert_equal @c2, @diagnostic.complementary_career
  end

  test "affirmation bonus can change ranking" do
    # Give c2 so many affirmations it overtakes c1 (c1 score=20, c2 score=15, need 6+ affirmations)
    affirmations = { @c2.id.to_s => %w[a b c d e f] }
    Diagnostics::ScoringService.call(@diagnostic, affirmations)
    @diagnostic.reload
    assert_equal @c2, @diagnostic.primary_career
  end

  test "sets status to pending_payment" do
    Diagnostics::ScoringService.call(@diagnostic, {})
    @diagnostic.reload
    assert @diagnostic.pending_payment?
  end

  test "sets completed_at" do
    Diagnostics::ScoringService.call(@diagnostic, {})
    @diagnostic.reload
    assert_not_nil @diagnostic.completed_at
  end

  test "rejects missing score data without completing diagnostic" do
    @diagnostic.update!(score_data: nil)

    assert_raises Diagnostics::ScoringService::InsufficientCareersError do
      Diagnostics::ScoringService.call(@diagnostic, {})
    end

    @diagnostic.reload
    assert @diagnostic.in_progress?
    assert_nil @diagnostic.completed_at
  end

  test "rejects unresolved careers without completing diagnostic" do
    @diagnostic.update!(score_data: {
      "top_career_ids" => [
        { "id" => @c1.id, "score" => 20 },
        { "id" => SecureRandom.uuid, "score" => 15 }
      ]
    })

    assert_raises Diagnostics::ScoringService::InsufficientCareersError do
      Diagnostics::ScoringService.call(@diagnostic, {})
    end

    @diagnostic.reload
    assert @diagnostic.in_progress?
    assert_nil @diagnostic.completed_at
  end

  test "persists affirmation_breakdown with checked affirmation text and bonus" do
    # checkbox values are the index into the career's affirmations array, e.g. "0" => "a", "2" => "c"
    affirmations = { @c2.id.to_s => %w[0 2] }
    Diagnostics::ScoringService.call(@diagnostic, affirmations)
    @diagnostic.reload

    breakdown = @diagnostic.score_data["affirmation_breakdown"][@c2.id.to_s]
    assert_equal %w[a c], breakdown["checked_affirmations"]
    assert_equal 2, breakdown["bonus"]
    assert_equal 6, breakdown["max_bonus"]
  end

  test "affirmation_breakdown bonus stays capped at the career's affirmation count" do
    affirmations = { @c2.id.to_s => %w[0 1 2 3 4 5 0 1] }
    Diagnostics::ScoringService.call(@diagnostic, affirmations)
    @diagnostic.reload

    breakdown = @diagnostic.score_data["affirmation_breakdown"][@c2.id.to_s]
    assert_equal 6, breakdown["bonus"]
    assert_equal 6, breakdown["max_bonus"]
  end

  test "affirmation_breakdown records zero bonus for a career with no checked affirmations" do
    Diagnostics::ScoringService.call(@diagnostic, {})
    @diagnostic.reload

    breakdown = @diagnostic.score_data["affirmation_breakdown"][@c1.id.to_s]
    assert_equal [], breakdown["checked_affirmations"]
    assert_equal 0, breakdown["bonus"]
    assert_equal 0, breakdown["max_bonus"]
  end
end
