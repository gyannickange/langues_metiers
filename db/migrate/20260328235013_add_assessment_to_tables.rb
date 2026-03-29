class AddAssessmentToTables < ActiveRecord::Migration[8.0]
  def change
    add_reference :assessment_questions, :assessment, type: :uuid, foreign_key: true, null: true
    add_reference :diagnostics, :assessment, type: :uuid, foreign_key: true, null: true
  end
end
