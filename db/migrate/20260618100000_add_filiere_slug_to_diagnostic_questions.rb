class AddFiliereSlugToDiagnosticQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :diagnostic_questions, :filiere_slug, :string
  end
end
