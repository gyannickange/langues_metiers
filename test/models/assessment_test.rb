require "test_helper"

class AssessmentTest < ActiveSupport::TestCase
  test "versions on update" do
    assessment = Assessment.create!(title: "Evaluation #{SecureRandom.hex(4)}", active: false)

    assert_difference -> { assessment.versions.count }, 1 do
      assessment.update!(title: "Evaluation renommée")
    end
  end
end
