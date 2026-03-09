require "test_helper"

class TrajectoryTest < ActiveSupport::TestCase
  def setup
    @career = Career.create!(title: "Analyste", slug: "analyste-#{SecureRandom.hex(4)}", status: :published, kind: :behavioral)
  end

  test "valid with a career" do
    assert Trajectory.new(career: @career).valid?
  end

  test "invalid without career" do
    assert_not Trajectory.new.valid?
  end

  test "active defaults to true" do
    t = Trajectory.create!(career: @career)
    assert t.active
  end

  test "scope active returns only active trajectories" do
    active   = Trajectory.create!(career: @career, active: true)
    inactive = Trajectory.create!(career: @career, active: false)
    assert_includes Trajectory.active, active
    assert_not_includes Trajectory.active, inactive
  end

  test "belongs_to career" do
    assert_respond_to Trajectory.new, :career
  end
end
