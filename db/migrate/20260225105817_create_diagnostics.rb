class CreateDiagnostics < ActiveRecord::Migration[8.0]
  def change
    create_table :diagnostics, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true,
                   type: :uuid, default: -> { "gen_random_uuid()" }
      t.integer  :status,                   null: false, default: 0
      t.integer  :payment_provider
      t.uuid     :primary_profile_id
      t.uuid     :complementary_profile_id
      t.jsonb    :score_data,               default: {}
      t.boolean  :pdf_generated,            default: false, null: false
      t.datetime :paid_at
      t.datetime :completed_at
      t.timestamps
    end
    add_foreign_key :diagnostics, :profiles, column: :primary_profile_id
    add_foreign_key :diagnostics, :profiles, column: :complementary_profile_id
  end
end
