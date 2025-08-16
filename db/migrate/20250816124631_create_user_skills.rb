class CreateUserSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :user_skills, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :skill, null: false, foreign_key: true, type: :uuid
      t.integer :level

      t.timestamps
    end
  end
end
