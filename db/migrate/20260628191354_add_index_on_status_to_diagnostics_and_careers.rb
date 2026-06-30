class AddIndexOnStatusToDiagnosticsAndCareers < ActiveRecord::Migration[8.0]
  def change
    add_index :diagnostics, :status
    add_index :careers, :status
  end
end
