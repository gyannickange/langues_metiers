class CreateCareers < ActiveRecord::Migration[8.0]
  def change
    create_table :careers, id: :uuid do |t|
      t.string :title
      t.text :description
      t.integer :status

      t.timestamps
    end
  end
end
