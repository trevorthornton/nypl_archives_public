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

ActiveRecord::Schema.define(:version => 20131126200725) do

  create_table "access_term_associations", :force => true do |t|
    t.integer  "describable_id"
    t.string   "describable_type"
    t.integer  "access_term_id"
    t.string   "role"
    t.boolean  "controlaccess",    :default => false
    t.boolean  "name_subject",     :default => false
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.string   "function"
    t.boolean  "questionable",     :default => false
  end

  add_index "access_term_associations", ["describable_id"], :name => "index_access_term_associations_on_describable_id"
  add_index "access_term_associations", ["describable_type"], :name => "index_access_term_associations_on_describable_type"

  create_table "access_terms", :force => true do |t|
    t.string   "term_original"
    t.string   "term_authorized"
    t.string   "term_type"
    t.string   "authority"
    t.string   "authority_record_id"
    t.string   "value_uri"
    t.integer  "control_source"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  add_index "access_terms", ["term_authorized"], :name => "index_access_terms_on_term_authorized"
  add_index "access_terms", ["term_original"], :name => "index_access_terms_on_term_original"
  add_index "access_terms", ["value_uri"], :name => "index_access_terms_on_value_uri"

  create_table "amat_records", :force => true do |t|
    t.integer  "collection_id"
    t.integer  "node_id"
    t.integer  "mss_id"
    t.string   "pdf_filename"
    t.string   "pdf_url"
    t.string   "ead_filename"
    t.string   "ead_url"
    t.boolean  "ead_ingest_error"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "verified"
  end

  create_table "catalog_imports", :force => true do |t|
    t.string   "bnumber"
    t.integer  "collection_id"
    t.date     "catalog_record_updated"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  create_table "collection_associations", :force => true do |t|
    t.integer  "describable_id"
    t.string   "describable_type"
    t.integer  "collection_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "collection_associations", ["describable_id"], :name => "index_collection_associations_on_describable_id"
  add_index "collection_associations", ["describable_type"], :name => "index_collection_associations_on_describable_type"

  create_table "collection_responses", :force => true do |t|
    t.integer  "collection_id"
    t.text     "desc_data",       :limit => 2147483647
    t.text     "structure",       :limit => 2147483647
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.text     "digital_objects", :limit => 2147483647
  end

  add_index "collection_responses", ["collection_id"], :name => "index_collection_responses_on_collection_id"

  create_table "collections", :force => true do |t|
    t.string   "title"
    t.string   "origination"
    t.integer  "org_unit_id"
    t.string   "date_statement"
    t.string   "extent_statement"
    t.float    "linear_feet"
    t.integer  "keydate"
    t.string   "identifier_value"
    t.string   "identifier_type"
    t.string   "bnumber"
    t.string   "call_number"
    t.string   "pdf_finding_aid"
    t.integer  "max_depth"
    t.integer  "series_count"
    t.boolean  "active",                                    :default => true, :null => false
    t.datetime "created_at",                                                  :null => false
    t.datetime "updated_at",                                                  :null => false
    t.text     "boost_queries",       :limit => 2147483647
    t.integer  "date_processed"
    t.integer  "component_layout_id"
  end

  add_index "collections", ["bnumber"], :name => "index_collections_on_bnumber"
  add_index "collections", ["identifier_type"], :name => "index_collections_on_identifier_type"
  add_index "collections", ["identifier_value"], :name => "index_collections_on_identifier_value"
  add_index "collections", ["keydate"], :name => "index_collections_on_keydate"
  add_index "collections", ["org_unit_id"], :name => "index_collections_on_org_unit_id"
  add_index "collections", ["title"], :name => "index_collections_on_title"

  create_table "component_layouts", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "component_responses", :force => true do |t|
    t.integer  "component_id"
    t.text     "desc_data",       :limit => 2147483647
    t.text     "structure",       :limit => 2147483647
    t.text     "digital_objects", :limit => 2147483647
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

  add_index "component_responses", ["component_id"], :name => "index_component_responses_on_component_id"

  create_table "components", :force => true do |t|
    t.string   "title"
    t.string   "origination"
    t.string   "identifier_value"
    t.string   "identifier_type"
    t.integer  "collection_id"
    t.integer  "parent_id"
    t.integer  "sib_seq"
    t.boolean  "has_children",                           :default => false
    t.integer  "level_num"
    t.string   "level_text"
    t.integer  "top_component_id"
    t.integer  "max_depth"
    t.integer  "org_unit_id"
    t.datetime "created_at",                                                :null => false
    t.datetime "updated_at",                                                :null => false
    t.string   "resource_type"
    t.string   "date_statement"
    t.string   "extent_statement"
    t.float    "linear_feet"
    t.integer  "load_seq"
    t.text     "boost_queries",    :limit => 2147483647
  end

  add_index "components", ["collection_id", "load_seq"], :name => "collection_load_seq"
  add_index "components", ["collection_id"], :name => "index_components_on_collection_id"
  add_index "components", ["identifier_type"], :name => "index_components_on_identifier_type"
  add_index "components", ["identifier_value"], :name => "index_components_on_identifier_value"
  add_index "components", ["org_unit_id"], :name => "index_components_on_org_unit_id"
  add_index "components", ["parent_id"], :name => "index_components_on_parent_id"
  add_index "components", ["title"], :name => "index_components_on_title"
  add_index "components", ["top_component_id"], :name => "index_components_on_top_component_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0, :null => false
    t.integer  "attempts",   :default => 0, :null => false
    t.text     "handler",                   :null => false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "descriptions", :force => true do |t|
    t.integer  "describable_id"
    t.string   "describable_type"
    t.text     "data",             :limit => 2147483647
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "descriptions", ["describable_id"], :name => "index_descriptions_on_describable_id"
  add_index "descriptions", ["describable_type"], :name => "index_descriptions_on_describable_type"

  create_table "documents", :force => true do |t|
    t.string   "describable_type"
    t.integer  "describable_id"
    t.string   "document_type"
    t.string   "description"
    t.string   "title"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.string   "file"
    t.boolean  "index_only",       :default => false
  end

  create_table "ead_ingests", :force => true do |t|
    t.integer  "collection_id"
    t.string   "update_type"
    t.string   "filename"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "external_resources", :force => true do |t|
    t.string   "describable_type"
    t.integer  "describable_id"
    t.string   "title"
    t.string   "description"
    t.string   "resource_type"
    t.string   "url"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "guide_guide_associations", :force => true do |t|
    t.integer  "parent_guide_id"
    t.integer  "child_guide_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "guides", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.string   "url_token"
    t.integer  "user_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "mods_exports", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "nypl_repo_objects", :force => true do |t|
    t.integer  "describable_id"
    t.string   "describable_type"
    t.string   "uuid"
    t.string   "resource_type"
    t.integer  "total_captures"
    t.text     "capture_ids",      :limit => 2147483647
    t.integer  "sib_seq"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "nypl_repo_objects", ["describable_id"], :name => "index_nypl_repo_objects_on_describable_id"
  add_index "nypl_repo_objects", ["describable_type"], :name => "index_nypl_repo_objects_on_describable_type"

  create_table "org_units", :force => true do |t|
    t.string   "name"
    t.string   "name_short"
    t.string   "code"
    t.integer  "sib_seq"
    t.string   "marc_org_code"
    t.string   "center"
    t.string   "location"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.text     "standard_access_note"
    t.string   "url"
    t.text     "description"
    t.integer  "collection_count"
    t.string   "email"
    t.text     "access_rules"
    t.text     "email_response_text"
  end

  create_table "place_name_associations", :force => true do |t|
    t.integer  "place_id"
    t.integer  "name_association_id"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.boolean  "questionable",        :default => false
  end

  create_table "record_guide_associations", :force => true do |t|
    t.text     "description"
    t.string   "describable_type"
    t.integer  "describable_id"
    t.integer  "guide_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "search_indices", :force => true do |t|
    t.string   "index_type"
    t.integer  "adds"
    t.integer  "updates"
    t.integer  "deletes"
    t.integer  "processing_errors"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.string   "index_scope"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
