class DiagnosticAnswer < ApplicationRecord
  belongs_to :diagnostic
  belongs_to :assessment_question
end
