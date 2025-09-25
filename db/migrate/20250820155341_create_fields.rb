class CreateFields < ActiveRecord::Migration[8.0]
  def change
    create_table :fields, id: :uuid do |t|
      t.string :name
      t.text :description
      t.string :slug
      t.integer :status

      t.timestamps
    end
    add_index :fields, :name, unique: true
    add_index :fields, :slug, unique: true
  end
end
