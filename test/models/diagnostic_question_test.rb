require "test_helper"

class DiagnosticQuestionTest < ActiveSupport::TestCase
  setup do
    @assessment = Assessment.create!(title: "Test #{SecureRandom.hex(4)}", active: false)
  end

  test "interest question valid with filiere_slug" do
    q = DiagnosticQuestion.new(
      assessment:   @assessment,
      kind:         :interest,
      text:         "Les langues m'attirent.",
      filiere_slug: "langues",
      position:     1
    )
    assert q.valid?, q.errors.full_messages.inspect
  end

  test "interest question invalid without filiere_slug" do
    q = DiagnosticQuestion.new(
      assessment: @assessment,
      kind:       :interest,
      text:       "Les langues m'attirent.",
      position:   1
    )
    assert_not q.valid?
    assert_includes q.errors[:filiere_slug], "ne peut pas être vide"
  end

  test "interest question does not require options" do
    q = DiagnosticQuestion.new(
      assessment:   @assessment,
      kind:         :interest,
      text:         "L'espace m'attire.",
      filiere_slug: "geo",
      position:     1
    )
    assert q.valid?, q.errors.full_messages.inspect
  end

  test "disc question requires disc_type" do
    q = DiagnosticQuestion.new(
      assessment: @assessment,
      kind:       :disc,
      text:       "Je décide vite.",
      position:   1
    )
    assert_not q.valid?
    assert_includes q.errors[:disc_type], "ne peut pas être vide"
  end

  test "competence question requires competence_slug" do
    q = DiagnosticQuestion.new(
      assessment: @assessment,
      kind:       :competence,
      text:       "Je parle une langue.",
      position:   1
    )
    assert_not q.valid?
    assert_includes q.errors[:competence_slug], "ne peut pas être vide"
  end

  test "disc_type must be D I S or C" do
    q = DiagnosticQuestion.new(
      assessment: @assessment,
      kind:       :disc,
      text:       "Je décide vite.",
      disc_type:  "Z",
      position:   1
    )
    assert_not q.valid?
  end
end
