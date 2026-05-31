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

ActiveRecord::Schema[8.1].define(version: 2026_03_16_101800) do
  create_table "api_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_used_at"
    t.string "name", null: false
    t.string "token_hash", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["token_hash"], name: "index_api_tokens_on_token_hash", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "appointments", force: :cascade do |t|
    t.text "completion_notes"
    t.datetime "created_at", null: false
    t.integer "job_id", null: false
    t.datetime "scheduled_end", null: false
    t.datetime "scheduled_start", null: false
    t.integer "technician_id", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_appointments_on_job_id"
    t.index ["technician_id", "scheduled_start"], name: "index_appointments_on_technician_id_and_scheduled_start"
    t.index ["technician_id"], name: "index_appointments_on_technician_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "contact_email"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "notes"
    t.string "phone"
    t.string "service_address", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invoice_line_items", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.integer "invoice_record_id", null: false
    t.string "kind", null: false
    t.integer "position", null: false
    t.float "quantity", null: false
    t.integer "unit_cents", null: false
    t.datetime "updated_at", null: false
    t.boolean "weekend", default: false, null: false
    t.index ["invoice_record_id", "position"], name: "index_invoice_line_items_on_invoice_record_id_and_position", unique: true
    t.index ["invoice_record_id"], name: "index_invoice_line_items_on_invoice_record_id"
  end

  create_table "invoice_records", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "job_id", null: false
    t.integer "labor_cents", null: false
    t.integer "parts_cents", null: false
    t.integer "total_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_invoice_records_on_job_id", unique: true
  end

  create_table "job_parts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "job_id", null: false
    t.integer "part_id", null: false
    t.integer "quantity", null: false
    t.integer "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_job_parts_on_job_id"
    t.index ["part_id"], name: "index_job_parts_on_part_id"
  end

  create_table "jobs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.text "description"
    t.string "priority", default: "normal", null: false
    t.string "status", default: "requested", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_jobs_on_customer_id"
    t.index ["priority"], name: "index_jobs_on_priority"
    t.index ["status"], name: "index_jobs_on_status"
  end

  create_table "parts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "sku", null: false
    t.integer "unit_cost_cents", null: false
    t.integer "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["sku"], name: "index_parts_on_sku", unique: true
  end

  create_table "stock_adjustments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "delta", null: false
    t.string "note"
    t.integer "part_id", null: false
    t.integer "quantity_after", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["part_id"], name: "index_stock_adjustments_on_part_id"
    t.index ["user_id"], name: "index_stock_adjustments_on_user_id"
  end

  create_table "stock_levels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "part_id", null: false
    t.integer "quantity_on_hand", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["part_id"], name: "index_stock_levels_on_part_id", unique: true
  end

  create_table "technicians", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "hourly_cost_cents", null: false
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.string "phone"
    t.json "skill_tags", default: [], null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.string "role", default: "dispatcher", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "api_tokens", "users"
  add_foreign_key "appointments", "jobs"
  add_foreign_key "appointments", "technicians"
  add_foreign_key "invoice_line_items", "invoice_records"
  add_foreign_key "invoice_records", "jobs"
  add_foreign_key "job_parts", "jobs"
  add_foreign_key "job_parts", "parts"
  add_foreign_key "jobs", "customers"
  add_foreign_key "stock_adjustments", "parts"
  add_foreign_key "stock_adjustments", "users"
  add_foreign_key "stock_levels", "parts"
end
