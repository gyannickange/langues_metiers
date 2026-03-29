class AddQuestionnaireToTables < ActiveRecord::Migration[8.0]
  def change
    add_reference :questions, :questionnaire, type: :uuid, foreign_key: true, null: true
    add_reference :diagnostics, :questionnaire, type: :uuid, foreign_key: true, null: true
  end
end
