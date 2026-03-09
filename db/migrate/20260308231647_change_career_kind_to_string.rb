class ChangeCareerKindToString < ActiveRecord::Migration[8.0]
  def up
    change_column :careers, :kind, :string, default: "behavioral", using: "CASE kind WHEN 0 THEN 'behavioral' WHEN 1 THEN 'profession' END"
  end

  def down
    change_column :careers, :kind, :integer, default: 0, using: "CASE kind WHEN 'behavioral' THEN 0 WHEN 'profession' THEN 1 END"
  end
end
