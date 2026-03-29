class CreateAssessments < ActiveRecord::Migration[8.0]
  def change
    create_table :assessments, id: :uuid do |t|
      t.string :title
      t.text :description
      t.boolean :active

      t.timestamps
    end
  end
end

