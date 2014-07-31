# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140731064354) do

  create_table "cases", force: true do |t|
    t.integer "patient_id"
    t.string  "anatomy"
    t.string  "side"
    t.string  "status",     default: "active"
  end

  add_index "cases", ["status"], name: "index_cases_on_status"

  create_table "patients", force: true do |t|
    t.string "name"
    t.date   "birth"
    t.string "gender", limit: 10
    t.date   "death"
    t.string "status",            default: "active"
  end

  add_index "patients", ["name", "birth"], name: "index_patients_on_name_and_birth"
  add_index "patients", ["status"], name: "index_patients_on_status"

end
