class DiagnosticAnswer < ApplicationRecord
  belongs_to :diagnostic
  belongs_to :assessment_question, optional: true
  belongs_to :diagnostic_question, optional: true
end
