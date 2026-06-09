require "test_helper"

class Diagnostics::ScoringServiceTest < ActiveSupport::TestCase
  def setup
    @user       = User.create!(email: "final#{SecureRandom.hex(4)}@test.com", password: "password123",
                                first_name: "Final", last_name: "Test", city: "Cotonou",
                                country: "BJ", diploma: "Licence", employment_status: "Étudiant")
    @assessment = Assessment.create!(title: "Final Score Test #{SecureRandom.hex(4)}", active: false)
    @diagnostic = Diagnostic.create!(user: @user, assessment: @assessment, status: :in_progress)

    @c1 = Career.create!(title: "Métier 1 #{SecureRandom.hex(4)}", slug: "metier-1-#{SecureRandom.hex(4)}", status: :published, filiere_slug: "langues", disc_types: [ "C" ], required_competences: [])
    @c2 = Career.create!(title: "Métier 2 #{SecureRandom.hex(4)}", slug: "metier-2-#{SecureRandom.hex(4)}", status: :published, filiere_slug: "socio",   disc_types: [ "I" ], required_competences: [], affirmations: %w[a b c d e f])
    @c3 = Career.create!(title: "Métier 3 #{SecureRandom.hex(4)}", slug: "metier-3-#{SecureRandom.hex(4)}", status: :published, filiere_slug: "lettres", disc_types: [ "S" ], required_competences: [])

    @diagnostic.update!(score_data: {
      "disc_scores"       => { "C" => 18 },
      "filiere_scores"    => { "langues" => 3 },
      "competence_scores" => {},
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
end
