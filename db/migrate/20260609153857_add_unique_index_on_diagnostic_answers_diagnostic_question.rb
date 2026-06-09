class AddUniqueIndexOnDiagnosticAnswersDiagnosticQuestion < ActiveRecord::Migration[8.0]
  def change
    add_index :diagnostic_answers, [:diagnostic_id, :diagnostic_question_id],
              unique: true,
              where: "diagnostic_question_id IS NOT NULL",
              name: "idx_diag_answers_on_diag_and_diag_quest"
  end
end
