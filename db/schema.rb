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

ActiveRecord::Schema[8.1].define(version: 2025_08_18_091200) do
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
    t.string "phone"
    t.string "service_address", null: false
    t.datetime "updated_at", null: false
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

  add_foreign_key "appointments", "jobs"
  add_foreign_key "appointments", "technicians"
  add_foreign_key "jobs", "customers"
end
