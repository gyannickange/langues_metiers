class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.jsonb :key_skills, default: []
      t.text :first_action
      t.text :premium_pitch
      t.timestamps
    end
    add_index :profiles, :slug, unique: true
  end
end
