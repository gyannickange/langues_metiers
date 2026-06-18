class DropAssessmentQuestionsAndCleanDiagnosticAnswers < ActiveRecord::Migration[8.0]
  def up
    # Remove index that includes assessment_question_id before dropping column
    remove_index :diagnostic_answers, name: "idx_diag_answers_on_diag_and_assess_quest", if_exists: true
    remove_index :diagnostic_answers, name: "index_diagnostic_answers_on_assessment_question_id", if_exists: true
    remove_column :diagnostic_answers, :assessment_question_id
    remove_foreign_key :assessment_questions, :assessments, if_exists: true
    drop_table :assessment_questions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
