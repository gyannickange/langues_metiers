class AddDiagnosticFieldsToCareers < ActiveRecord::Migration[8.0]
  def change
    add_column :careers, :disc_types,           :jsonb, default: []
    add_column :careers, :academic_field_slug,   :string
    add_column :careers, :affirmations,          :jsonb, default: []
  end
end
