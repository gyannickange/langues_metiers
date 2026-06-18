class AddDiagnosticFieldsToCareers < ActiveRecord::Migration[8.0]
  def change
    add_column :careers, :disc_types,           :jsonb, default: []
    add_column :careers, :filiere_slug,          :string
    add_column :careers, :required_competences,  :jsonb, default: []
    add_column :careers, :affirmations,          :jsonb, default: []
  end
end
