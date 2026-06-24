class CreateFilieres < ActiveRecord::Migration[8.0]
  def change
    create_table :filieres, id: :uuid do |t|
      t.string  :slug
      t.string  :name
      t.integer :position

      t.timestamps
    end

    add_index :filieres, :slug, unique: true
  end
end
