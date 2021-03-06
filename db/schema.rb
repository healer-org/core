# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_12_27_132546) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appointments", id: :serial, force: :cascade do |t|
    t.integer "patient_id"
    t.integer "trip_id"
    t.integer "order"
    t.date "date"
    t.datetime "start"
    t.datetime "end"
    t.string "location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["patient_id"], name: "index_appointments_on_patient_id"
    t.index ["trip_id", "start", "location"], name: "index_appointments_on_trip_id_and_start_and_location"
  end

  create_table "attachments", id: :serial, force: :cascade do |t|
    t.integer "record_id"
    t.string "record_type"
    t.text "description"
    t.string "document_file_name"
    t.string "document_content_type"
    t.integer "document_file_size"
    t.datetime "document_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_id"], name: "index_attachments_on_record_id"
    t.index ["record_type", "record_id"], name: "index_attachments_on_record_type_and_record_id"
  end

  create_table "cases", id: :serial, force: :cascade do |t|
    t.integer "patient_id"
    t.string "anatomy"
    t.string "side"
    t.string "status", default: "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["status"], name: "index_cases_on_status"
  end

  create_table "missions", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "country", limit: 2
    t.string "location"
    t.string "facility"
    t.date "begin_date"
    t.date "end_date"
    t.index ["begin_date"], name: "index_missions_on_begin_date"
  end

  create_table "missions_teams", id: :serial, force: :cascade do |t|
    t.integer "mission_id", null: false
    t.integer "team_id", null: false
    t.index ["team_id"], name: "index_missions_teams_on_team_id"
  end

  create_table "patients", id: :serial, force: :cascade do |t|
    t.string "name"
    t.date "birth"
    t.string "gender", limit: 10
    t.date "death"
    t.string "status", default: "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name", "birth"], name: "index_patients_on_name_and_birth"
    t.index ["status"], name: "index_patients_on_status"
  end

  create_table "procedures", id: :serial, force: :cascade do |t|
    t.integer "case_id", null: false
    t.integer "appointment_id"
    t.jsonb "data"
  end

  create_table "procedures_providers", force: :cascade do |t|
    t.integer "procedure_id", null: false
    t.integer "provider_id", null: false
    t.index ["procedure_id"], name: "index_procedures_providers_on_procedure_id"
    t.index ["provider_id"], name: "index_procedures_providers_on_provider_id"
  end

  create_table "providers", force: :cascade do |t|
    t.string "name"
  end

  create_table "providers_teams", force: :cascade do |t|
    t.integer "provider_id", null: false
    t.integer "team_id", null: false
    t.index ["provider_id"], name: "index_providers_teams_on_provider_id"
    t.index ["team_id"], name: "index_providers_teams_on_team_id"
  end

  create_table "teams", id: :serial, force: :cascade do |t|
    t.string "name", null: false
  end

end
