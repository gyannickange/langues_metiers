class CreateTrajectories < ActiveRecord::Migration[8.0]
  def change
    create_table :trajectories, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :profile, null: false, foreign_key: true,
                   type: :uuid, default: -> { "gen_random_uuid()" }
      t.text :axe_1
      t.text :axe_2
      t.text :axe_3
      t.boolean :active, default: true, null: false
      t.timestamps
    end
  end
end
