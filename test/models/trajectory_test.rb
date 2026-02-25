require "test_helper"

class TrajectoryTest < ActiveSupport::TestCase
  def setup
    @profile = Profile.create!(name: "Analyste", slug: "analyste-#{SecureRandom.hex(4)}")
  end

  test "valid with a profile" do
    assert Trajectory.new(profile: @profile).valid?
  end

  test "invalid without profile" do
    assert_not Trajectory.new.valid?
  end

  test "active defaults to true" do
    t = Trajectory.create!(profile: @profile)
    assert t.active
  end

  test "scope active returns only active trajectories" do
    active   = Trajectory.create!(profile: @profile, active: true)
    inactive = Trajectory.create!(profile: @profile, active: false)
    assert_includes Trajectory.active, active
    assert_not_includes Trajectory.active, inactive
  end

  test "belongs_to profile" do
    assert_respond_to Trajectory.new, :profile
  end
end
