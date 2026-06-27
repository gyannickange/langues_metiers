class AddAcademicFieldSlugToDiagnosticQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :diagnostic_questions, :academic_field_slug, :string
  end
end
