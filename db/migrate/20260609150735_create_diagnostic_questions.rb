class CreateDiagnosticQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :diagnostic_questions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :assessment, type: :uuid, foreign_key: true, null: false
      t.string  :kind,            null: false
      t.text    :text,            null: false
      t.string  :disc_type
      t.string  :skill_slug
      t.jsonb   :options,         default: []
      t.integer :position,        default: 1, null: false
      t.boolean :active,          default: true, null: false
      t.timestamps
    end
    add_index :diagnostic_questions, [ :assessment_id, :kind, :position ]
  end
end
