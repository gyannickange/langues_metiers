class AddSlugAndPositionToSkills < ActiveRecord::Migration[8.0]
  def change
    add_column :skills, :slug, :string
    add_column :skills, :position, :integer
    add_index  :skills, :slug, unique: true
  end
end
