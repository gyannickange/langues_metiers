class DiagnosticAnswer < ApplicationRecord
  belongs_to :diagnostic
  belongs_to :diagnostic_question, optional: true
  belongs_to :career, optional: true

  validate :exactly_one_answer_source

  private

  def exactly_one_answer_source
    question_answer    = diagnostic_question_id.present?
    affirmation_answer = career_id.present? && affirmation_index.present? && affirmation_text.present?

    errors.add(:base, "Answer source is invalid") unless question_answer ^ affirmation_answer
  end
end
