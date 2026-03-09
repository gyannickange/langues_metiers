class MergeProfilesIntoCareers < ActiveRecord::Migration[8.0]
  def up
    add_column :careers, :slug, :string
    add_column :careers, :kind, :integer, default: 0
    add_column :careers, :key_skills, :jsonb, default: []
    add_column :careers, :first_action, :text
    add_column :careers, :premium_pitch, :text

    execute <<-SQL
      INSERT INTO careers (id, title, slug, description, key_skills, first_action, premium_pitch, kind, status, created_at, updated_at)
      SELECT id, name, slug, description, COALESCE(key_skills, '[]'::jsonb), first_action, premium_pitch, 0, 1, created_at, updated_at
      FROM profiles;
    SQL

    # Update trajectories
    remove_foreign_key :trajectories, :profiles
    rename_column :trajectories, :profile_id, :career_id
    add_foreign_key :trajectories, :careers, column: :career_id

    # Update diagnostics
    remove_foreign_key :diagnostics, column: :primary_profile_id
    rename_column :diagnostics, :primary_profile_id, :primary_career_id
    add_foreign_key :diagnostics, :careers, column: :primary_career_id

    remove_foreign_key :diagnostics, column: :complementary_profile_id
    rename_column :diagnostics, :complementary_profile_id, :complementary_career_id
    add_foreign_key :diagnostics, :careers, column: :complementary_career_id

    drop_table :profiles do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.jsonb :key_skills, default: []
      t.text :first_action
      t.text :premium_pitch
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index [ "slug" ], name: "index_profiles_on_slug", unique: true
    end

    add_index :careers, :slug, unique: true, where: "slug IS NOT NULL"
  end

  def down
    remove_index :careers, :slug

    create_table :profiles, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.jsonb :key_skills, default: []
      t.text :first_action
      t.text :premium_pitch
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    add_index :profiles, :slug, unique: true

    remove_foreign_key :diagnostics, column: :primary_career_id
    rename_column :diagnostics, :primary_career_id, :primary_profile_id
    add_foreign_key :diagnostics, :profiles, column: :primary_profile_id

    remove_foreign_key :diagnostics, column: :complementary_career_id
    rename_column :diagnostics, :complementary_career_id, :complementary_profile_id
    add_foreign_key :diagnostics, :profiles, column: :complementary_profile_id

    remove_foreign_key :trajectories, column: :career_id
    rename_column :trajectories, :career_id, :profile_id
    add_foreign_key :trajectories, :profiles, column: :profile_id

    remove_column :careers, :slug
    remove_column :careers, :kind
    remove_column :careers, :key_skills
    remove_column :careers, :first_action
    remove_column :careers, :premium_pitch
  end
end
