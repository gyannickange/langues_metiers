require "test_helper"

class CareerTest < ActiveSupport::TestCase
  test "valid factory" do
    assert Career.new(title: "Analyste & Veille", slug: "analyste-veille", status: :published, kind: :behavioral).valid?
  end

  test "invalid without title" do
    p = Career.new(slug: "test")
    assert_not p.valid?
    assert_includes p.errors[:title], "doit être rempli(e)"
  end

  test "invalid without slug" do
    p = Career.new(title: "Test")
    assert_not p.valid?
    assert_includes p.errors[:slug], "doit être rempli(e)"
  end

  test "unique slug" do
    Career.create!(title: "P1", slug: "my-slug", status: :published, kind: :behavioral)
    assert_not Career.new(title: "P2", slug: "my-slug", status: :published, kind: :behavioral).valid?
  end

  test "slug is parameterized before validation" do
    p = Career.create!(title: "Test", slug: "test-#{SecureRandom.hex(4)}", status: :published, kind: :behavioral)
    p.update!(slug: "Un Slug Invalide")
    assert_equal "un-slug-invalide", p.slug
  end

  test "has_many trajectories" do
    assert_respond_to Career.new, :trajectories
  end
end
