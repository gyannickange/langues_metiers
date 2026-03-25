class CreateCareers < ActiveRecord::Migration[8.0]
  def change
    create_table :careers, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
