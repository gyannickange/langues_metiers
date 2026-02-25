require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  test "valid with name and slug" do
    assert Profile.new(name: "Analyste & Veille", slug: "analyste-veille").valid?
  end

  test "invalid without name" do
    p = Profile.new(slug: "test")
    assert_not p.valid?
    assert p.errors[:name].any?
  end

  test "invalid without slug" do
    p = Profile.new(name: "Test")
    assert_not p.valid?
    assert p.errors[:slug].any?
  end

  test "slug must be unique" do
    Profile.create!(name: "P1", slug: "my-slug")
    assert_not Profile.new(name: "P2", slug: "my-slug").valid?
  end

  test "key_skills defaults to empty array" do
    p = Profile.create!(name: "Test", slug: "test-#{SecureRandom.hex(4)}")
    assert_equal [], p.key_skills
  end

  test "has_many trajectories" do
    assert_respond_to Profile.new, :trajectories
  end
end
