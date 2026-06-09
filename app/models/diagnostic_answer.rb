class DiagnosticAnswer < ApplicationRecord
  belongs_to :diagnostic
  belongs_to :assessment_question
  belongs_to :diagnostic_question, optional: true
end
