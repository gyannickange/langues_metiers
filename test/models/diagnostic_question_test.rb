require "test_helper"

class DiagnosticQuestionTest < ActiveSupport::TestCase
  setup do
    @assessment = Assessment.create!(title: "Test #{SecureRandom.hex(4)}", active: false)
  end

  test "interest question valid with academic_field_slug" do
    q = DiagnosticQuestion.new(
      assessment:   @assessment,
      kind:         :interest,
      text:         "Les langues m'attirent.",
      academic_field_slug: "langues",
      position:     1
    )
    assert q.valid?, q.errors.full_messages.inspect
  end

  test "interest question invalid without academic_field_slug" do
    q = DiagnosticQuestion.new(
      assessment: @assessment,
      kind:       :interest,
      text:       "Les langues m'attirent.",
      position:   1
    )
    assert_not q.valid?
    assert_includes q.errors[:academic_field_slug], "ne peut pas être vide"
  end

  test "interest question does not require options" do
    q = DiagnosticQuestion.new(
      assessment:   @assessment,
      kind:         :interest,
      text:         "L'espace m'attire.",
      academic_field_slug: "geo",
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

  test "skill question requires skill_slug" do
    q = DiagnosticQuestion.new(
      assessment: @assessment,
      kind:       :skill,
      text:       "Je parle une langue.",
      position:   1
    )
    assert_not q.valid?
    assert_includes q.errors[:skill_slug], "ne peut pas être vide"
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

  test "skill_label writes into the options array" do
    q = DiagnosticQuestion.new
    q.skill_label = "  Langues étrangères  "
    assert_equal [ { "label" => "Langues étrangères" } ], q.options
    assert_equal "Langues étrangères", q.skill_label
  end

  test "blank skill_label clears the options array" do
    q = DiagnosticQuestion.new(options: [ { "label" => "X" } ])
    q.skill_label = ""
    assert_equal [], q.options
    assert_nil q.skill_label
  end

  test "skill_label is nil when options is not an array of hashes" do
    assert_nil DiagnosticQuestion.new(options: nil).skill_label
    assert_nil DiagnosticQuestion.new(options: [ "foo" ]).skill_label
  end
end
