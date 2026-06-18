class MakeAssessmentQuestionOptionalInDiagnosticAnswers < ActiveRecord::Migration[8.0]
  def up
    # Remove the FK constraint so assessment_question_id can be nil
    remove_foreign_key :diagnostic_answers, :assessment_questions, if_exists: true

    # Change assessment_question_id to be nullable
    change_column_null :diagnostic_answers, :assessment_question_id, true

    # Remove the DB-level default (random UUID) so nil is used when not provided
    change_column_default :diagnostic_answers, :assessment_question_id, from: -> { "gen_random_uuid()" }, to: nil
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
