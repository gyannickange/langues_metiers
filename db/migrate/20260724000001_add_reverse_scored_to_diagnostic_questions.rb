class AddReverseScoredToDiagnosticQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :diagnostic_questions, :reverse_scored, :boolean, default: false, null: false
  end
end
