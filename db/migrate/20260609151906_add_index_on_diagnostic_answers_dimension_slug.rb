class AddIndexOnDiagnosticAnswersDimensionSlug < ActiveRecord::Migration[8.0]
  def change
    add_index :diagnostic_answers, :dimension_slug
  end
end
