class CreateRoadmapFields < ActiveRecord::Migration[8.0]
  def change
    create_table :roadmap_fields, id: :uuid do |t|
      t.references :roadmap, null: false, foreign_key: true, type: :uuid
      t.references :field, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :roadmap_fields, [ :roadmap_id, :field_id ], unique: true
  end
end
