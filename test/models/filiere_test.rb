require "test_helper"

class FiliereTest < ActiveSupport::TestCase
  test "requires a slug" do
    filiere = Filiere.new(name: "Test")

    assert_not filiere.valid?
    assert_includes filiere.errors[:slug], "doit être rempli(e)"
  end

  test "requires a name" do
    filiere = Filiere.new(slug: "test")

    assert_not filiere.valid?
    assert_includes filiere.errors[:name], "doit être rempli(e)"
  end

  test "requires a unique slug" do
    Filiere.create!(slug: "test-slug", name: "Premier")
    duplicate = Filiere.new(slug: "test-slug", name: "Second")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "est déjà utilisé(e)"
  end
end
