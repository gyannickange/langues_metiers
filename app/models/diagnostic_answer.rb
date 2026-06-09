class DiagnosticAnswer < ApplicationRecord
  belongs_to :diagnostic
  belongs_to :assessment_question, optional: true
  belongs_to :diagnostic_question, optional: true

  validate :must_reference_one_question

  private

  def must_reference_one_question
    if assessment_question_id.nil? && diagnostic_question_id.nil?
      errors.add(:base, "must belong to either an assessment_question or a diagnostic_question")
    end
  end
end
