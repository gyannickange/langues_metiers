require "test_helper"

class Diagnostics::VocabularyTest < ActiveSupport::TestCase
  test "filiere slugs match the eight diagnostic filieres" do
    assert_equal %w[langues geo socio lettres psycho philo histoire edu].sort,
                 Diagnostics::Vocabulary.filiere_slugs.sort
  end

  test "competence slugs cover the twelve diagnostic competences" do
    assert_equal 12, Diagnostics::Vocabulary.competence_slugs.length
    assert_includes Diagnostics::Vocabulary.competence_slugs, "langues_etrangeres"
    assert_includes Diagnostics::Vocabulary.competence_slugs, "droit_politiques"
  end

  test "disc type slugs are the four DISC letters" do
    assert_equal %w[D I S C], Diagnostics::Vocabulary.disc_type_slugs
  end

  test "option helpers return [label, slug] pairs for selects" do
    assert_equal [ "Langues", "langues" ], Diagnostics::Vocabulary.filiere_options.first
    assert_equal [ "Dominant", "D" ], Diagnostics::Vocabulary.disc_type_options.first
    label, slug = Diagnostics::Vocabulary.competence_options.first
    assert_equal "Langues étrangères", label
    assert_equal "langues_etrangeres", slug
  end
end
