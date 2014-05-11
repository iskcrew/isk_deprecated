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

ActiveRecord::Schema.define(:version => 20140510192530) do

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

  create_table "display_counts", :force => true do |t|
    t.integer  "count",      :default => 0
    t.integer  "slide_id"
    t.integer  "display_id"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "display_counts", ["display_id", "slide_id"], :name => "index_display_counts_on_display_id_and_slide_id"
  add_index "display_counts", ["display_id"], :name => "index_display_counts_on_display_id"
  add_index "display_counts", ["slide_id"], :name => "index_display_counts_on_slide_id"

  create_table "display_states", :force => true do |t|
    t.integer  "display_id"
    t.integer  "current_group_id"
    t.integer  "current_slide_id"
    t.datetime "last_contact_at"
    t.datetime "last_hello"
    t.string   "websocket_connection_id"
    t.string   "ip",                      :limit => 12
    t.boolean  "monitor",                               :default => true
    t.datetime "created_at",                                              :null => false
    t.datetime "updated_at",                                              :null => false
  end

  create_table "displays", :force => true do |t|
    t.string   "name",            :limit => 50
    t.integer  "presentation_id"
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
    t.boolean  "manual",                        :default => false
    t.boolean  "do_overrides",                  :default => true
  end

  add_index "displays", ["name"], :name => "index_displays_on_name", :unique => true
  add_index "displays", ["presentation_id"], :name => "index_displays_on_presentation_id"

  create_table "effects", :force => true do |t|
    t.string   "name",        :limit => 100
    t.string   "description", :limit => 200
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  create_table "events", :force => true do |t|
    t.string   "name",                            :null => false
    t.boolean  "current",      :default => false, :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "ungrouped_id"
    t.integer  "thrashed_id"
  end

  add_index "events", ["current"], :name => "index_events_on_current"

  create_table "groups", :force => true do |t|
    t.integer  "position"
    t.integer  "master_group_id"
    t.integer  "presentation_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "groups", ["master_group_id"], :name => "index_groups_on_master_group_id"
  add_index "groups", ["presentation_id", "position"], :name => "index_groups_on_presentation_id_and_position"
  add_index "groups", ["presentation_id"], :name => "index_groups_on_presentation_id"

  create_table "master_groups", :force => true do |t|
    t.string   "name",       :limit => 100
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.integer  "event_id"
    t.boolean  "internal",                  :default => false
    t.string   "type"
  end

  add_index "master_groups", ["event_id"], :name => "index_master_groups_on_event_id"

  create_table "override_queues", :force => true do |t|
    t.integer  "display_id"
    t.integer  "position"
    t.integer  "duration",   :default => 60
    t.integer  "slide_id"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  add_index "override_queues", ["display_id", "position"], :name => "index_override_queues_on_display_id_and_position"
  add_index "override_queues", ["slide_id"], :name => "index_override_queues_on_slide_id"

  create_table "permissions", :force => true do |t|
    t.integer  "role_id"
    t.integer  "user_id"
    t.integer  "master_group_id"
    t.integer  "display_id_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "display_id"
    t.integer  "presentation_id"
    t.integer  "slide_id"
  end

  add_index "permissions", ["role_id"], :name => "index_roles_users_on_role_id"
  add_index "permissions", ["user_id"], :name => "index_roles_users_on_user_id"

  create_table "presentations", :force => true do |t|
    t.string   "name",       :limit => 100
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "delay",                     :default => 30
    t.integer  "effect_id",                 :default => 1
    t.integer  "event_id"
  end

  create_table "roles", :force => true do |t|
    t.string   "role",        :limit => 50,                  :null => false
    t.string   "description", :limit => 100, :default => ""
    t.string   "controller",  :limit => 50
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
  end

  create_table "schedule_events", :force => true do |t|
    t.integer  "schedule_id"
    t.datetime "at"
    t.string   "name"
    t.string   "description"
    t.string   "location"
    t.boolean  "major",       :default => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.boolean  "cancelled",   :default => false
    t.boolean  "rescheduled", :default => false
    t.string   "external_id"
    t.integer  "linecount",   :default => 1
  end

  create_table "schedules", :force => true do |t|
    t.integer  "event_id"
    t.string   "name"
    t.integer  "slidegroup_id"
    t.integer  "up_next_group_id"
    t.boolean  "up_next",                :default => true
    t.integer  "max_slides",             :default => -1
    t.integer  "min_events_on_next_day", :default => 3
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
  end

  create_table "slides", :force => true do |t|
    t.string   "name",              :limit => 100
    t.string   "filename",          :limit => 50
    t.integer  "replacement_id"
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.boolean  "ready",                            :default => false
    t.integer  "master_group_id"
    t.integer  "position"
    t.boolean  "deleted",                          :default => false
    t.boolean  "is_svg",                           :default => false
    t.boolean  "public",                           :default => false
    t.boolean  "show_clock",                       :default => true
    t.string   "type"
    t.text     "description"
    t.datetime "images_updated_at"
    t.integer  "duration",                         :default => -1
  end

  add_index "slides", ["id", "public"], :name => "index_slides_on_id_and_public"
  add_index "slides", ["id", "type"], :name => "index_slides_on_id_and_type"
  add_index "slides", ["master_group_id"], :name => "index_slides_on_master_group_id"
  add_index "slides", ["replacement_id"], :name => "index_slides_on_replacement_id"

  create_table "users", :force => true do |t|
    t.string   "username",   :limit => 50
    t.string   "password",   :limit => 50
    t.string   "salt",       :limit => 50
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

end
