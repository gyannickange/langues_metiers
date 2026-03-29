class DiagnosticReminderJob < ApplicationJob
  queue_as :default

  def perform(diagnostic_id, delay_type)
    diagnostic = Diagnostic.find_by(id: diagnostic_id)
    return unless diagnostic

    # Send email only if still in_progress
    return unless diagnostic.in_progress?

    DiagnosticMailer.incomplete_reminder(diagnostic.id, delay_type).deliver_now
  end
end
