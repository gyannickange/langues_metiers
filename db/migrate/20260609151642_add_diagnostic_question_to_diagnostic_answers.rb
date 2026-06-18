class AddDiagnosticQuestionToDiagnosticAnswers < ActiveRecord::Migration[8.0]
  def change
    add_reference :diagnostic_answers, :diagnostic_question,
                  type: :uuid, foreign_key: true, null: true
    add_column :diagnostic_answers, :dimension_slug, :string
  end
end
