class AddSelectedSkillsToDiagnostics < ActiveRecord::Migration[8.0]
  def change
    add_column :diagnostics, :selected_skills, :jsonb, default: [], null: false
  end
end
