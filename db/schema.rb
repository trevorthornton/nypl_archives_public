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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130108160537) do

  create_table "access_term_associations", :force => true do |t|
    t.integer  "describable_id"
    t.string   "describable_type"
    t.integer  "access_term_id"
    t.boolean  "name_subject"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.boolean  "controlaccess"
    t.string   "role"
  end

  create_table "access_terms", :force => true do |t|
    t.string   "term_original"
    t.string   "term_authorized"
    t.string   "term_type"
    t.string   "authority"
    t.string   "authority_record_id"
    t.string   "value_uri"
    t.integer  "authority_control_agent"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  create_table "collection_associations", :force => true do |t|
    t.integer  "describable_id"
    t.string   "describable_type"
    t.integer  "collection_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "collections", :force => true do |t|
    t.string   "title"
    t.string   "identifier_value"
    t.string   "identifier_type"
    t.integer  "org_unit_id"
    t.boolean  "active",           :default => true
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.string   "origination"
    t.string   "catalog_url"
    t.string   "date_statement"
    t.integer  "keydate"
  end

  add_index "collections", ["identifier_type"], :name => "index_collections_on_identifier_type"
  add_index "collections", ["identifier_value"], :name => "index_collections_on_identifier_value"
  add_index "collections", ["org_unit_id"], :name => "index_collections_on_org_unit_id"
  add_index "collections", ["title"], :name => "index_collections_on_title"

  create_table "components", :force => true do |t|
    t.string   "title"
    t.string   "identifier_value"
    t.string   "identifier_type"
    t.integer  "collection_id"
    t.integer  "parent_id"
    t.integer  "sib_seq"
    t.integer  "level_num"
    t.string   "level_text"
    t.integer  "org_unit_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.boolean  "has_children"
    t.integer  "max_levels"
    t.integer  "top_component_id"
  end

  add_index "components", ["identifier_type"], :name => "index_components_on_identifier_type"
  add_index "components", ["identifier_value"], :name => "index_components_on_identifier_value"
  add_index "components", ["org_unit_id"], :name => "index_components_on_org_unit_id"
  add_index "components", ["title"], :name => "index_components_on_title"

  create_table "descriptions", :force => true do |t|
    t.integer  "describable_id"
    t.string   "describable_type"
    t.text     "descriptive_identity",   :limit => 2147483647
    t.text     "content_structure",      :limit => 2147483647
    t.text     "context",                :limit => 2147483647
    t.text     "acquisition_processing", :limit => 2147483647
    t.text     "related_material",       :limit => 2147483647
    t.text     "access_use",             :limit => 2147483647
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.text     "notes",                  :limit => 2147483647
  end

  create_table "ead_ingests", :force => true do |t|
    t.integer  "collection_id"
    t.string   "filename"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "nypl_repo_objects", :force => true do |t|
    t.string   "uuid"
    t.string   "object_type"
    t.integer  "total_captures"
    t.text     "capture_ids",      :limit => 2147483647
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.integer  "describable_id"
    t.string   "describable_type"
  end

  create_table "org_units", :force => true do |t|
    t.string   "name"
    t.string   "name_short"
    t.string   "code"
    t.string   "center"
    t.string   "marc_org_code"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "search_indices", :force => true do |t|
    t.string   "index_type"
    t.integer  "adds"
    t.integer  "updates"
    t.integer  "deletes"
    t.integer  "processing_errors"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

end
