require "test_helper"

class DiagnosticQuestionTest < ActiveSupport::TestCase
  def setup
    @assessment = Assessment.create!(title: "Test #{SecureRandom.hex(4)}", active: false)
  end

  test "valid disc question" do
    q = DiagnosticQuestion.new(assessment: @assessment, kind: :disc, text: "Je prends des décisions sous pression.", disc_type: "D", position: 1)
    assert q.valid?, q.errors.full_messages.inspect
  end

  test "disc question invalid without disc_type" do
    q = DiagnosticQuestion.new(assessment: @assessment, kind: :disc, text: "X", position: 1)
    assert_not q.valid?
    assert_includes q.errors[:disc_type], "ne peut pas être vide"
  end

  test "disc_type must be D I S or C" do
    q = DiagnosticQuestion.new(assessment: @assessment, kind: :disc, text: "X", disc_type: "Z", position: 1)
    assert_not q.valid?
  end

  test "valid interest question" do
    opts = [ { "label" => "Écrire", "filiere_slug" => "lettres" } ]
    q = DiagnosticQuestion.new(assessment: @assessment, kind: :interest, text: "Vous aimez :", options: opts, position: 1)
    assert q.valid?, q.errors.full_messages.inspect
  end

  test "interest question invalid without options" do
    q = DiagnosticQuestion.new(assessment: @assessment, kind: :interest, text: "X", options: [], position: 1)
    assert_not q.valid?
  end

  test "valid competence question" do
    q = DiagnosticQuestion.new(assessment: @assessment, kind: :competence, text: "Je parle une langue.", competence_slug: "langues_etrangeres", position: 1)
    assert q.valid?, q.errors.full_messages.inspect
  end

  test "competence question invalid without competence_slug" do
    q = DiagnosticQuestion.new(assessment: @assessment, kind: :competence, text: "X", position: 1)
    assert_not q.valid?
  end

  test "active scope excludes inactive questions" do
    DiagnosticQuestion.create!(assessment: @assessment, kind: :competence, text: "A", competence_slug: "ecoute", position: 1, active: true)
    DiagnosticQuestion.create!(assessment: @assessment, kind: :competence, text: "B", competence_slug: "creativite", position: 2, active: false)
    assert_equal 1, DiagnosticQuestion.where(assessment: @assessment).active.count
  end

  test "ordered scope returns by position" do
    DiagnosticQuestion.create!(assessment: @assessment, kind: :competence, text: "Z", competence_slug: "ecoute", position: 3)
    DiagnosticQuestion.create!(assessment: @assessment, kind: :competence, text: "A", competence_slug: "creativite", position: 1)
    positions = DiagnosticQuestion.where(assessment: @assessment).ordered.pluck(:position)
    assert_equal positions.sort, positions
  end
end
