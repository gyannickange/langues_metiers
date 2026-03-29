class CreateDiagnosticAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :diagnostic_answers, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :diagnostic, null: false, foreign_key: true,
                   type: :uuid, default: -> { "gen_random_uuid()" }
      t.references :assessment_question, null: false, foreign_key: true,
                   type: :uuid, default: -> { "gen_random_uuid()" }
      t.string  :answer_value
      t.string  :profile_dimension
      t.integer :points_awarded, default: 0
      t.timestamps
    end
    add_index :diagnostic_answers, [ :diagnostic_id, :assessment_question_id ], unique: true, name: "idx_diag_answers_on_diag_and_assess_quest"
  end
end
