require "test_helper"

class Diagnostics::LikertScoringTest < ActiveSupport::TestCase
  test "effective_value returns the raw value when not reversed" do
    assert_equal 4, Diagnostics::LikertScoring.effective_value(4, reverse_scored: false)
  end

  test "effective_value inverts the value on a 1-5 scale when reversed" do
    assert_equal 2, Diagnostics::LikertScoring.effective_value(4, reverse_scored: true)
    assert_equal 5, Diagnostics::LikertScoring.effective_value(1, reverse_scored: true)
    assert_equal 1, Diagnostics::LikertScoring.effective_value(5, reverse_scored: true)
    assert_equal 3, Diagnostics::LikertScoring.effective_value(3, reverse_scored: true)
  end

  test "average returns the arithmetic mean" do
    assert_equal 4.5, Diagnostics::LikertScoring.average([ 5, 4 ])
    assert_in_delta 3.33, Diagnostics::LikertScoring.average([ 2, 4, 4 ]), 0.01
  end

  test "average of an empty list is zero" do
    assert_equal 0.0, Diagnostics::LikertScoring.average([])
  end

  test "normalize maps 1..5 onto 0..100" do
    assert_equal 0.0, Diagnostics::LikertScoring.normalize(1)
    assert_equal 50.0, Diagnostics::LikertScoring.normalize(3)
    assert_equal 100.0, Diagnostics::LikertScoring.normalize(5)
  end
end
