class CreateQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :questions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.integer  :bloc,     null: false
      t.text     :text,     null: false
      t.string   :kind,     null: false, default: "mcq"
      t.jsonb    :options,  default: []
      t.boolean  :scored,   default: false, null: false
      t.integer  :position, null: false, default: 0
      t.boolean  :active,   default: true, null: false
      t.timestamps
    end
    add_index :questions, [:bloc, :position]
  end
end
