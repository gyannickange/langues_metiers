class CreateRoadmaps < ActiveRecord::Migration[8.0]
  def change
    create_table :roadmaps, id: :uuid do |t|
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
