class RemoveDefaultFromDiagnosticAnswersDiagnosticId < ActiveRecord::Migration[8.0]
  def change
    change_column_default :diagnostic_answers, :diagnostic_id,
                          from: -> { "gen_random_uuid()" },
                          to: nil
  end
end
