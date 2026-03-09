class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user,       null: false, foreign_key: true,
                   type: :uuid, default: -> { "gen_random_uuid()" }
      t.references :diagnostic, null: false, foreign_key: true,
                   type: :uuid, default: -> { "gen_random_uuid()" }
      t.integer :provider,            null: false
      t.integer :amount_cents,        null: false, default: 300000
      t.string  :currency,            null: false, default: "XOF"
      t.integer :status,              null: false, default: 0
      t.string  :provider_payment_id
      t.datetime :webhook_confirmed_at
      t.timestamps
    end
    add_index :payments, :provider_payment_id, unique: true,
              where: "provider_payment_id IS NOT NULL"
  end
end
