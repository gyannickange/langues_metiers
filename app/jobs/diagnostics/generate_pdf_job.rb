# app/jobs/diagnostics/generate_pdf_job.rb
module Diagnostics
  class GeneratePdfJob < ApplicationJob
    queue_as :default

    def perform(diagnostic_id)
      diagnostic = Diagnostic.find_by(id: diagnostic_id)
      return if diagnostic.nil? || diagnostic.pdf_generated?
      Diagnostics::GeneratePdfService.call(diagnostic)
    end
  end
end
