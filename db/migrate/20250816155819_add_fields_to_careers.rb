class AddFieldsToCareers < ActiveRecord::Migration[8.0]
  def change
    add_column :careers, :required_skills, :jsonb, default: []
    add_column :careers, :recommended_path, :text
    add_column :careers, :sector, :string
  end
end
