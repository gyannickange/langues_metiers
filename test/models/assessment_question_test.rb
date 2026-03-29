require "test_helper"

class AssessmentQuestionTest < ActiveSupport::TestCase
  test "valid with required attributes" do
    assert AssessmentQuestion.new(bloc: 1, text: "Votre orientation ?", kind: "mcq", position: 1).valid?
  end

  test "invalid without bloc" do
    assert_not AssessmentQuestion.new(text: "Q", kind: "mcq", position: 1).valid?
  end

  test "invalid without text" do
    assert_not AssessmentQuestion.new(bloc: 1, kind: "mcq", position: 1).valid?
  end

  test "invalid kind" do
    aq = AssessmentQuestion.new(bloc: 1, text: "Q", kind: "bad", position: 1)
    assert_not aq.valid?
  end


  test "scope active" do
    a = AssessmentQuestion.create!(bloc: 1, text: "A", kind: "mcq", position: 1, active: true)
    i = AssessmentQuestion.create!(bloc: 1, text: "I", kind: "mcq", position: 2, active: false)
    assert_includes AssessmentQuestion.active, a
    assert_not_includes AssessmentQuestion.active, i
  end

  test "scope by_bloc returns ordered by position" do
    aq2 = AssessmentQuestion.create!(bloc: 1, text: "aq2", kind: "mcq", position: 2)
    aq1 = AssessmentQuestion.create!(bloc: 1, text: "aq1", kind: "mcq", position: 1)
    assert_equal [ aq1, aq2 ], AssessmentQuestion.by_bloc(1).to_a
  end
end
