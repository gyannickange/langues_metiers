class AddAffirmationFieldsToDiagnosticAnswers < ActiveRecord::Migration[8.0]
  def change
    add_reference :diagnostic_answers, :career, type: :uuid, foreign_key: true, null: true
    add_column :diagnostic_answers, :affirmation_index, :integer
    add_column :diagnostic_answers, :affirmation_text, :string
    add_column :diagnostic_answers, :effective_value, :integer

    add_index :diagnostic_answers, [ :diagnostic_id, :career_id, :affirmation_index ],
              unique: true,
              where: "career_id IS NOT NULL",
              name: "idx_diag_answers_on_diag_and_career_affirmation"
  end
end
