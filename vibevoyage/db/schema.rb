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

ActiveRecord::Schema[8.0].define(version: 2025_07_29_234608) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "itineraries", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.jsonb "themes"
    t.text "narrative_html"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.string "city"
    t.index ["user_id"], name: "index_itineraries_on_user_id"
  end

  create_table "itinerary_stops", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "address"
    t.float "latitude"
    t.float "longitude"
    t.string "opening_hours"
    t.bigint "itinerary_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "qloo_data"
    t.integer "position"
    t.text "cultural_explanation"
    t.string "why_chosen"
    t.string "qloo_keywords"
    t.index ["itinerary_id"], name: "index_itinerary_stops_on_itinerary_id"
    t.index ["position"], name: "index_itinerary_stops_on_position"
  end

  create_table "subscription_plans", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.decimal "price", precision: 8, scale: 2, null: false
    t.text "description"
    t.json "features", default: []
    t.integer "max_journeys_per_month", default: 1
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_subscription_plans_on_active"
    t.index ["slug"], name: "index_subscription_plans_on_slug", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string "name"
    t.decimal "price"
    t.string "status"
    t.text "features"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "subscription_plan_id"
    t.string "subscription_status", default: "free"
    t.datetime "subscription_expires_at"
    t.integer "journeys_this_month", default: 0
    t.date "last_journey_reset"
    t.string "first_name"
    t.string "last_name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["subscription_expires_at"], name: "index_users_on_subscription_expires_at"
    t.index ["subscription_plan_id"], name: "index_users_on_subscription_plan_id"
    t.index ["subscription_status"], name: "index_users_on_subscription_status"
  end

  create_table "vibe_profiles", force: :cascade do |t|
    t.string "category"
    t.string "entity"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "description"
    t.index ["user_id"], name: "index_vibe_profiles_on_user_id"
  end

  add_foreign_key "itineraries", "users"
  add_foreign_key "itinerary_stops", "itineraries"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "users", "subscription_plans"
  add_foreign_key "vibe_profiles", "users"
end
