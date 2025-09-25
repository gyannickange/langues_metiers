class CreateRoadmapSteps < ActiveRecord::Migration[8.0]
  def change
    create_table :roadmap_steps, id: :uuid do |t|
      t.string :title
      t.text :objective
      t.text :skills
      t.text :activities
      t.integer :order
      t.references :roadmap, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
    add_index :roadmap_steps, [ :roadmap_id, :order ], unique: true
  end
end
