class DiagnosticAnswer < ApplicationRecord
  belongs_to :diagnostic
  belongs_to :question
end
