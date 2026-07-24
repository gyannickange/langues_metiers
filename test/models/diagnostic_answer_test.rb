require "test_helper"

class DiagnosticAnswerTest < ActiveSupport::TestCase
  def setup
    @user       = User.create!(email: "answer#{SecureRandom.hex(4)}@test.com", password: "password123",
                                first_name: "Answer", last_name: "Test", city: "Cotonou",
                                country: "BJ", diploma: "Licence", employment_status: "Étudiant")
    @assessment = Assessment.create!(title: "Answer Test #{SecureRandom.hex(4)}", active: false)
    @diagnostic = Diagnostic.create!(user: @user, assessment: @assessment, status: :in_progress)
    @question   = @assessment.diagnostic_questions.create!(kind: :disc, text: "Q?", disc_type: "D", position: 1)
    @career     = Career.create!(title: "Analyste #{SecureRandom.hex(4)}", status: :published, affirmations: [ "Ça me ressemble." ])
  end

  test "valid with only a diagnostic_question source" do
    answer = @diagnostic.diagnostic_answers.new(diagnostic_question: @question, answer_value: "4", points_awarded: 4)
    assert answer.valid?, answer.errors.full_messages.inspect
  end

  test "valid with only a career affirmation source, including affirmation_index zero" do
    answer = @diagnostic.diagnostic_answers.new(
      career: @career, affirmation_index: 0, affirmation_text: "Ça me ressemble.",
      answer_value: "5", points_awarded: 5, effective_value: 5
    )
    assert answer.valid?, answer.errors.full_messages.inspect
  end

  test "invalid with neither source" do
    answer = @diagnostic.diagnostic_answers.new(answer_value: "4", points_awarded: 4)
    assert_not answer.valid?
    assert_includes answer.errors[:base], "Answer source is invalid"
  end

  test "invalid with both sources at once" do
    answer = @diagnostic.diagnostic_answers.new(
      diagnostic_question: @question, career: @career, affirmation_index: 0, affirmation_text: "X",
      answer_value: "4", points_awarded: 4
    )
    assert_not answer.valid?
    assert_includes answer.errors[:base], "Answer source is invalid"
  end

  test "invalid with a career but no affirmation_index or affirmation_text" do
    answer = @diagnostic.diagnostic_answers.new(career: @career, answer_value: "4", points_awarded: 4)
    assert_not answer.valid?
    assert_includes answer.errors[:base], "Answer source is invalid"
  end
end
