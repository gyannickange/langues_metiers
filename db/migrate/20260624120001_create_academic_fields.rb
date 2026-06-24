class CreateAcademicFields < ActiveRecord::Migration[8.0]
  def change
    create_table :academic_fields, id: :uuid do |t|
      t.string  :slug
      t.string  :name
      t.integer :position

      t.timestamps
    end

    add_index :academic_fields, :slug, unique: true
  end
end
