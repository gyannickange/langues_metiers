require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  test "valid with required attributes" do
    assert Question.new(bloc: 1, text: "Votre orientation ?", kind: "mcq", position: 1).valid?
  end

  test "invalid without bloc" do
    assert_not Question.new(text: "Q", kind: "mcq", position: 1).valid?
  end

  test "invalid without text" do
    assert_not Question.new(bloc: 1, kind: "mcq", position: 1).valid?
  end

  test "invalid kind" do
    q = Question.new(bloc: 1, text: "Q", kind: "bad", position: 1)
    assert_not q.valid?
  end

  test "bloc must be 1 through 5" do
    assert_not Question.new(bloc: 6, text: "Q", kind: "mcq", position: 1).valid?
    assert_not Question.new(bloc: 0, text: "Q", kind: "mcq", position: 1).valid?
  end

  test "scope active" do
    a = Question.create!(bloc: 1, text: "A", kind: "mcq", position: 1, active: true)
    i = Question.create!(bloc: 1, text: "I", kind: "mcq", position: 2, active: false)
    assert_includes Question.active, a
    assert_not_includes Question.active, i
  end

  test "scope by_bloc returns ordered by position" do
    q2 = Question.create!(bloc: 1, text: "Q2", kind: "mcq", position: 2)
    q1 = Question.create!(bloc: 1, text: "Q1", kind: "mcq", position: 1)
    assert_equal [q1, q2], Question.by_bloc(1).to_a
  end
end
