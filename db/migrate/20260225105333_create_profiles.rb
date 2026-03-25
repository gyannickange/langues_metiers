class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :careers, :slug, :string unless column_exists?(:careers, :slug)
    add_column :careers, :kind, :integer, default: 0 unless column_exists?(:careers, :kind)
    add_column :careers, :key_skills, :jsonb, default: [] unless column_exists?(:careers, :key_skills)
    add_column :careers, :first_action, :text unless column_exists?(:careers, :first_action)
    add_column :careers, :premium_pitch, :text unless column_exists?(:careers, :premium_pitch)

    add_index :careers, :slug, unique: true unless index_exists?(:careers, :slug)
  end
end
