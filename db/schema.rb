# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_02_25_115128) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "careers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "required_skills"
    t.text "recommended_path"
    t.string "sector"
  end

  create_table "categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "kind"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "categories_skills", id: false, force: :cascade do |t|
    t.uuid "category_id", null: false
    t.uuid "skill_id", null: false
    t.index ["category_id", "skill_id"], name: "index_categories_skills_on_category_id_and_skill_id", unique: true
    t.index ["category_id"], name: "index_categories_skills_on_category_id"
    t.index ["skill_id"], name: "index_categories_skills_on_skill_id"
  end

  create_table "diagnostic_answers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "diagnostic_id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "question_id", default: -> { "gen_random_uuid()" }, null: false
    t.string "answer_value"
    t.string "profile_dimension"
    t.integer "points_awarded", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["diagnostic_id", "question_id"], name: "index_diagnostic_answers_on_diagnostic_id_and_question_id", unique: true
    t.index ["diagnostic_id"], name: "index_diagnostic_answers_on_diagnostic_id"
    t.index ["question_id"], name: "index_diagnostic_answers_on_question_id"
  end

  create_table "diagnostics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", default: -> { "gen_random_uuid()" }, null: false
    t.integer "status", default: 0, null: false
    t.integer "payment_provider"
    t.uuid "primary_profile_id"
    t.uuid "complementary_profile_id"
    t.jsonb "score_data", default: {}
    t.boolean "pdf_generated", default: false, null: false
    t.datetime "paid_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_diagnostics_on_user_id"
  end

  create_table "fields", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "slug"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_fields_on_name", unique: true
    t.index ["slug"], name: "index_fields_on_slug", unique: true
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "mobile_operators", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.string "country_code", null: false
    t.string "logo_url"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code", "country_code"], name: "index_mobile_operators_on_code_and_country_code", unique: true
    t.index ["country_code"], name: "index_mobile_operators_on_country_code"
  end

  create_table "payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "diagnostic_id", default: -> { "gen_random_uuid()" }, null: false
    t.integer "provider", null: false
    t.integer "amount_cents", default: 300000, null: false
    t.string "currency", default: "XOF", null: false
    t.integer "status", default: 0, null: false
    t.string "provider_payment_id"
    t.datetime "webhook_confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["diagnostic_id"], name: "index_payments_on_diagnostic_id"
    t.index ["provider_payment_id"], name: "index_payments_on_provider_payment_id", unique: true, where: "(provider_payment_id IS NOT NULL)"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.jsonb "key_skills", default: []
    t.text "first_action"
    t.text "premium_pitch"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_profiles_on_slug", unique: true
  end

  create_table "questions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "bloc", null: false
    t.text "text", null: false
    t.string "kind", default: "mcq", null: false
    t.jsonb "options", default: []
    t.boolean "scored", default: false, null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bloc", "position"], name: "index_questions_on_bloc_and_position"
  end

  create_table "roadmap_fields", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "roadmap_id", null: false
    t.uuid "field_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["field_id"], name: "index_roadmap_fields_on_field_id"
    t.index ["roadmap_id", "field_id"], name: "index_roadmap_fields_on_roadmap_id_and_field_id", unique: true
    t.index ["roadmap_id"], name: "index_roadmap_fields_on_roadmap_id"
  end

  create_table "roadmap_steps", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.text "objective"
    t.text "skills"
    t.text "activities"
    t.integer "order"
    t.uuid "roadmap_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["roadmap_id", "order"], name: "index_roadmap_steps_on_roadmap_id_and_order", unique: true
    t.index ["roadmap_id"], name: "index_roadmap_steps_on_roadmap_id"
  end

  create_table "roadmaps", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "skills", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trajectories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "profile_id", default: -> { "gen_random_uuid()" }, null: false
    t.text "axe_1"
    t.text "axe_2"
    t.text "axe_3"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["profile_id"], name: "index_trajectories_on_profile_id"
  end

  create_table "user_skills", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "skill_id", null: false
    t.integer "level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["skill_id"], name: "index_user_skills_on_skill_id"
    t.index ["user_id"], name: "index_user_skills_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "role", default: 0, null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "categories_skills", "categories"
  add_foreign_key "categories_skills", "skills"
  add_foreign_key "diagnostic_answers", "diagnostics"
  add_foreign_key "diagnostic_answers", "questions"
  add_foreign_key "diagnostics", "profiles", column: "complementary_profile_id"
  add_foreign_key "diagnostics", "profiles", column: "primary_profile_id"
  add_foreign_key "diagnostics", "users"
  add_foreign_key "payments", "diagnostics"
  add_foreign_key "payments", "users"
  add_foreign_key "roadmap_fields", "fields"
  add_foreign_key "roadmap_fields", "roadmaps"
  add_foreign_key "roadmap_steps", "roadmaps"
  add_foreign_key "trajectories", "profiles"
  add_foreign_key "user_skills", "skills"
  add_foreign_key "user_skills", "users"
end
