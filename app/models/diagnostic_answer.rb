class DiagnosticAnswer < ApplicationRecord
  belongs_to :diagnostic
  belongs_to :diagnostic_question

  validates :diagnostic_question_id, presence: true
end
