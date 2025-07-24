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

ActiveRecord::Schema[8.0].define(version: 2025_07_23_223815) do
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

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
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
  add_foreign_key "vibe_profiles", "users"
end
