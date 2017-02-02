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

ActiveRecord::Schema.define(version: 20170131031949) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.boolean  "closed",          default: false, null: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "identity_number",                 null: false
    t.string   "country_code",                    null: false
  end

  create_table "accounts_roles", id: false, force: :cascade do |t|
    t.integer "account_id"
    t.integer "role_id"
    t.index ["account_id", "role_id"], name: "index_accounts_roles_on_account_id_and_role_id", using: :btree
    t.index ["account_id"], name: "index_accounts_roles_on_account_id", using: :btree
    t.index ["role_id"], name: "index_accounts_roles_on_role_id", using: :btree
  end

  create_table "balances", force: :cascade do |t|
    t.decimal  "amount",      precision: 8, scale: 2, null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "account_id"
    t.integer  "document_id"
    t.index ["account_id"], name: "index_balances_on_account_id", using: :btree
    t.index ["document_id"], name: "index_balances_on_document_id", using: :btree
  end

  create_table "blocked_operations", force: :cascade do |t|
    t.string   "operation",  null: false
    t.integer  "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_blocked_operations_on_account_id", using: :btree
  end

  create_table "correspondent_accounts", force: :cascade do |t|
    t.decimal  "amount",     precision: 8, scale: 2, null: false
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "documents", force: :cascade do |t|
    t.json     "params",                                    null: false
    t.string   "status",                                    null: false
    t.string   "document_type",                             null: false
    t.integer  "document_number",                           null: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.decimal  "amount",            precision: 8, scale: 2
    t.integer  "source_account_id"
    t.integer  "target_account_id"
    t.integer  "folder_id"
    t.string   "reason"
    t.index ["document_number"], name: "index_documents_on_document_number", using: :btree
    t.index ["folder_id"], name: "index_documents_on_folder_id", using: :btree
    t.index ["source_account_id"], name: "index_documents_on_source_account_id", using: :btree
    t.index ["target_account_id"], name: "index_documents_on_target_account_id", using: :btree
  end

  create_table "folders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "folder_id",  null: false
  end

  create_table "held_balances", force: :cascade do |t|
    t.decimal  "amount",      precision: 8, scale: 2, null: false
    t.integer  "account_id"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "document_id"
    t.index ["account_id"], name: "index_held_balances_on_account_id", using: :btree
    t.index ["document_id"], name: "index_held_balances_on_document_id", using: :btree
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.string   "resource_type"
    t.integer  "resource_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
    t.index ["name"], name: "index_roles_on_name", using: :btree
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource_type_and_resource_id", using: :btree
  end

  add_foreign_key "balances", "accounts"
  add_foreign_key "balances", "documents"
  add_foreign_key "blocked_operations", "accounts"
  add_foreign_key "documents", "folders"
  add_foreign_key "held_balances", "accounts"
  add_foreign_key "held_balances", "documents"
end
