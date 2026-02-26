class CreateMobileOperators < ActiveRecord::Migration[8.0]
  def change
    create_table :mobile_operators, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string  :name,         null: false
      t.string  :code,         null: false
      t.string  :country_code, null: false
      t.string  :logo_url
      t.boolean :active, default: true, null: false
      t.timestamps
    end
    add_index :mobile_operators, [:code, :country_code], unique: true
    add_index :mobile_operators, :country_code
  end
end
