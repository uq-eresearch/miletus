# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema
# definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more
# migrations you'll amass, the slower it'll run and the greater likelihood for
# issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121005032727) do

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

  create_table "harvest_atom_rdc_entries", :force => true do |t|
    t.integer "feed_id"
    t.text    "xml"
    t.string  "atom_id"
  end

  create_table "harvest_atom_rdc_feeds", :force => true do |t|
    t.string  "url",         :null => false
    t.integer "entry_count"
  end

  create_table "merge_concepts", :force => true do |t|
    t.text     "cache"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.integer  "facets_count"
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

  add_index "merge_indexed_attributes", ["concept_id", "key", "value"],
    :name => "index_merge_indexed_attributes_on_concept_id_and_key_and_value",
    :unique => true
  add_index "merge_indexed_attributes", ["key", "value"],
    :name => "index_merge_indexed_attributes_on_key_and_value"

  create_table "oaipmh_rifcs_record_collections", :force => true do |t|
    t.string "endpoint", :null => false
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

  create_table "output_oaipmh_records", :force => true do |t|
    t.integer  "underlying_concept_id"
    t.integer  "set_memberships_id"
    t.text     "metadata"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  create_table "output_oaipmh_sets", :force => true do |t|
    t.integer  "set_memberships_id"
    t.string   "spec",               :null => false
    t.string   "name",               :null => false
    t.string   "description"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "sru_interfaces", :force => true do |t|
    t.string "endpoint", :null => false
    t.text   "details",  :null => false
  end

end
