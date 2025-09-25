class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories, id: :uuid do |t|
      t.string :name
      t.string :kind

      t.timestamps
    end
  end
end
