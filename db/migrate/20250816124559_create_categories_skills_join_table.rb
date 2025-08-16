class CreateCategoriesSkillsJoinTable < ActiveRecord::Migration[8.0]
  def change
    create_table :categories_skills, id: false do |t|
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.references :skill, null: false, foreign_key: true, type: :uuid
    end

    add_index :categories_skills, [ :category_id, :skill_id ], unique: true
  end
end
