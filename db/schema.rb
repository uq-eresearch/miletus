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

ActiveRecord::Schema.define(:version => 20131003034552) do

  create_table "active_admin_comments", :force => true do |t|
    t.string   "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "admin_users", :force => true do |t|
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

  add_index "admin_users", ["email"], :name => "index_admin_users_on_email", :unique => true
  add_index "admin_users", ["reset_password_token"], :name => "index_admin_users_on_reset_password_token", :unique => true

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
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

  create_table "facet_links", :force => true do |t|
    t.integer  "facet_id"
    t.integer  "harvest_record_id"
    t.string   "harvest_record_type"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  create_table "harvest_atom_entries", :force => true do |t|
    t.integer  "feed_id"
    t.string   "identifier"
    t.string   "updated"
    t.text     "xml"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "harvest_atom_entry_documents", :force => true do |t|
    t.integer  "entry_id"
    t.integer  "document_id"
    t.text     "info"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "harvest_atom_feeds", :force => true do |t|
    t.string   "url"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "harvest_documents", :force => true do |t|
    t.string   "type",                                     :null => false
    t.string   "url",                                      :null => false
    t.string   "etag"
    t.string   "last_modified"
    t.string   "document_file_name"
    t.string   "document_content_type"
    t.integer  "document_file_size"
    t.datetime "document_updated_at"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.boolean  "managed",               :default => false
  end

  create_table "merge_concepts", :force => true do |t|
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.text     "cache"
    t.integer  "facets_count"
    t.string   "sort_key"
    t.string   "uuid"
  end

  create_table "merge_facets", :force => true do |t|
    t.integer  "concept_id"
    t.string   "key"
    t.text     "metadata"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "merge_indexed_attributes", :force => true do |t|
    t.integer "concept_id"
    t.string  "key",        :null => false
    t.text    "value"
  end

  add_index "merge_indexed_attributes", ["concept_id", "key", "value"], :name => "index_merge_indexed_attributes_on_concept_id_and_key_and_value", :unique => true
  add_index "merge_indexed_attributes", ["key", "value"], :name => "index_merge_indexed_attributes_on_key_and_value"

  create_table "oaipmh_rifcs_record_collections", :force => true do |t|
    t.string "endpoint", :null => false
    t.string "set"
  end

  create_table "oaipmh_rifcs_records", :force => true do |t|
    t.integer  "record_collection_id"
    t.string   "identifier",                              :null => false
    t.datetime "datestamp",                               :null => false
    t.text     "metadata",                                :null => false
    t.boolean  "deleted",              :default => false, :null => false
  end

  create_table "output_oaipmh_record_set_memberships", :force => true do |t|
    t.integer "record_id"
    t.integer "set_id"
  end

  add_index "output_oaipmh_record_set_memberships", ["record_id"], :name => "index_output_oaipmh_record_set_memberships_on_record_id"
  add_index "output_oaipmh_record_set_memberships", ["set_id"], :name => "index_output_oaipmh_record_set_memberships_on_set_id"

  create_table "output_oaipmh_records", :force => true do |t|
    t.integer  "underlying_concept_id"
    t.text     "metadata"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  create_table "output_oaipmh_sets", :force => true do |t|
    t.string   "spec",        :null => false
    t.string   "name",        :null => false
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "pages", :force => true do |t|
    t.string   "name"
    t.text     "content"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "sru_interfaces", :force => true do |t|
    t.string "endpoint", :null => false
    t.text   "details",  :null => false
  end

end
