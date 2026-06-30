class RemoveBehavioralCareerSupport < ActiveRecord::Migration[8.0]
  def up
    behavioral_ids = execute("SELECT id FROM careers WHERE kind = 'behavioral'").map { |row| row["id"] }
    if behavioral_ids.any?
      ids_list = behavioral_ids.map { |id| "'#{id}'" }.join(",")
      execute("UPDATE diagnostics SET primary_career_id = NULL WHERE primary_career_id IN (#{ids_list})")
      execute("UPDATE diagnostics SET complementary_career_id = NULL WHERE complementary_career_id IN (#{ids_list})")
      execute("DELETE FROM trajectories WHERE career_id IN (#{ids_list})")
      execute("DELETE FROM careers WHERE id IN (#{ids_list})")
    end

    remove_column :careers, :kind
    remove_column :careers, :key_skills
  end

  def down
    add_column :careers, :kind, :string, default: "behavioral"
    add_column :careers, :key_skills, :jsonb, default: []
    execute("UPDATE careers SET kind = 'profession'")
  end
end
