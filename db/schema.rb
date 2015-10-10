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

ActiveRecord::Schema.define(version: 20151010084944) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",               default: 0
    t.integer  "attempts",               default: 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "display_counts", force: :cascade do |t|
    t.integer  "count",      default: 0
    t.integer  "slide_id"
    t.integer  "display_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "display_counts", ["display_id", "slide_id"], name: "index_display_counts_on_display_id_and_slide_id", using: :btree
  add_index "display_counts", ["display_id"], name: "index_display_counts_on_display_id", using: :btree
  add_index "display_counts", ["slide_id"], name: "index_display_counts_on_slide_id", using: :btree

  create_table "display_states", force: :cascade do |t|
    t.integer  "display_id"
    t.integer  "current_group_id"
    t.integer  "current_slide_id"
    t.datetime "last_contact_at"
    t.datetime "last_hello"
    t.string   "websocket_connection_id", limit: 255
    t.string   "ip",                      limit: 255
    t.boolean  "monitor",                             default: true
    t.datetime "created_at",                                                   null: false
    t.datetime "updated_at",                                                   null: false
    t.string   "status",                  limit: 255, default: "disconnected"
  end

  add_index "display_states", ["display_id"], name: "index_display_states_on_display_id", using: :btree
  add_index "display_states", ["last_contact_at"], name: "index_display_states_on_last_contact_at", using: :btree

  create_table "displays", force: :cascade do |t|
    t.string   "name",            limit: 50
    t.integer  "presentation_id"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.boolean  "manual",                     default: false
    t.boolean  "do_overrides",               default: true
  end

  add_index "displays", ["name"], name: "index_displays_on_name", unique: true, using: :btree
  add_index "displays", ["presentation_id"], name: "index_displays_on_presentation_id", using: :btree

  create_table "effects", force: :cascade do |t|
    t.string   "name",        limit: 100
    t.string   "description", limit: 200
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "events", force: :cascade do |t|
    t.string   "name",                     limit: 255,                     null: false
    t.boolean  "current",                              default: false,     null: false
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.integer  "ungrouped_id"
    t.integer  "thrashed_id"
    t.text     "config"
    t.integer  "resolution",                           default: 1,         null: false
    t.integer  "schedules_per_slide",                  default: 9,         null: false
    t.integer  "schedules_line_length",                default: 30,        null: false
    t.integer  "schedules_tolerance",                  default: 15,        null: false
    t.string   "schedules_subheader_fill",             default: "#e2e534", null: false
    t.integer  "schedules_time_indent",                default: 60,        null: false
    t.integer  "schedules_event_indent",               default: 290,       null: false
    t.integer  "schedules_font_size",                  default: 72,        null: false
    t.integer  "schedules_line_spacing",               default: 100,       null: false
    t.integer  "simple_heading_font_size",             default: 120,       null: false
    t.integer  "simple_heading_x",                     default: 60,        null: false
    t.integer  "simple_heading_y",                     default: 130,       null: false
    t.integer  "simple_body_margin_left",              default: 60,        null: false
    t.integer  "simple_body_margin_right",             default: 1860,      null: false
    t.integer  "simple_body_y",                        default: 280,       null: false
  end

  add_index "events", ["current"], name: "index_events_on_current", using: :btree

  create_table "groups", force: :cascade do |t|
    t.integer  "position"
    t.integer  "master_group_id"
    t.integer  "presentation_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "groups", ["master_group_id"], name: "index_groups_on_master_group_id", using: :btree
  add_index "groups", ["presentation_id", "position"], name: "index_groups_on_presentation_id_and_position", using: :btree
  add_index "groups", ["presentation_id"], name: "index_groups_on_presentation_id", using: :btree

  create_table "master_groups", force: :cascade do |t|
    t.string   "name",         limit: 100
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.integer  "event_id"
    t.boolean  "internal",                 default: false
    t.string   "type",         limit: 255
    t.integer  "effect_id"
    t.integer  "slides_count"
  end

  add_index "master_groups", ["effect_id"], name: "index_master_groups_on_effect_id", using: :btree
  add_index "master_groups", ["event_id"], name: "index_master_groups_on_event_id", using: :btree
  add_index "master_groups", ["internal"], name: "index_master_groups_on_internal", using: :btree

  create_table "override_queues", force: :cascade do |t|
    t.integer  "display_id"
    t.integer  "position"
    t.integer  "duration",   default: 60
    t.integer  "slide_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "effect_id",  default: 1
  end

  add_index "override_queues", ["display_id", "position"], name: "index_override_queues_on_display_id_and_position", using: :btree
  add_index "override_queues", ["effect_id"], name: "index_override_queues_on_effect_id", using: :btree
  add_index "override_queues", ["position"], name: "index_override_queues_on_position", using: :btree
  add_index "override_queues", ["slide_id"], name: "index_override_queues_on_slide_id", using: :btree

  create_table "permissions", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "target_id"
    t.string   "target_type", limit: 255
  end

  add_index "permissions", ["target_id", "target_type"], name: "index_permissions_on_target_id_and_target_type", using: :btree
  add_index "permissions", ["user_id"], name: "index_roles_users_on_user_id", using: :btree

  create_table "presentations", force: :cascade do |t|
    t.string   "name",       limit: 100
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "delay",                  default: 30
    t.integer  "effect_id",              default: 1
    t.integer  "event_id"
  end

  add_index "presentations", ["effect_id"], name: "index_presentations_on_effect_id", using: :btree
  add_index "presentations", ["event_id"], name: "index_presentations_on_event_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "role",        limit: 50,               null: false
    t.string   "description", limit: 100, default: ""
    t.string   "controller",  limit: 50
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  create_table "schedule_events", force: :cascade do |t|
    t.integer  "schedule_id"
    t.datetime "at"
    t.string   "name",        limit: 255
    t.string   "description", limit: 255
    t.string   "location",    limit: 255
    t.boolean  "major",                   default: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.boolean  "cancelled",               default: false
    t.boolean  "rescheduled",             default: false
    t.string   "external_id", limit: 255
    t.integer  "linecount",               default: 1
  end

  create_table "schedules", force: :cascade do |t|
    t.integer  "event_id"
    t.string   "name",                   limit: 255
    t.integer  "slidegroup_id"
    t.integer  "next_up_group_id"
    t.boolean  "next_up",                            default: true
    t.integer  "max_slides",                         default: -1
    t.integer  "min_events_on_next_day",             default: 3
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.string   "next_up_header"
    t.string   "slide_header"
  end

  add_index "schedules", ["event_id"], name: "index_schedules_on_event_id", using: :btree
  add_index "schedules", ["next_up_group_id"], name: "index_schedules_on_next_up_group_id", using: :btree
  add_index "schedules", ["slidegroup_id"], name: "index_schedules_on_slidegroup_id", using: :btree

  create_table "slide_templates", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "event_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted",                default: false
  end

  add_index "slide_templates", ["deleted"], name: "index_slide_templates_on_deleted", using: :btree
  add_index "slide_templates", ["event_id"], name: "index_slide_templates_on_event_id", using: :btree

  create_table "slides", force: :cascade do |t|
    t.string   "name",              limit: 100
    t.string   "filename",          limit: 50
    t.integer  "replacement_id"
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.boolean  "ready",                         default: false
    t.integer  "master_group_id"
    t.integer  "position"
    t.boolean  "deleted",                       default: false
    t.boolean  "is_svg",                        default: false
    t.boolean  "public",                        default: false
    t.boolean  "show_clock",                    default: true
    t.string   "type",              limit: 255
    t.text     "description"
    t.datetime "images_updated_at"
    t.integer  "duration",                      default: -1
    t.integer  "foreign_object_id"
  end

  add_index "slides", ["foreign_object_id"], name: "index_slides_on_foreign_object_id", using: :btree
  add_index "slides", ["id", "public"], name: "index_slides_on_id_and_public", using: :btree
  add_index "slides", ["id", "type"], name: "index_slides_on_id_and_type", using: :btree
  add_index "slides", ["master_group_id"], name: "index_slides_on_master_group_id", using: :btree
  add_index "slides", ["replacement_id"], name: "index_slides_on_replacement_id", using: :btree

  create_table "template_fields", force: :cascade do |t|
    t.integer  "slide_template_id"
    t.boolean  "editable",                      default: false
    t.boolean  "multiline",                     default: false
    t.string   "color",             limit: 255, default: "#00ff00"
    t.text     "default_value"
    t.string   "element_id",        limit: 255
    t.integer  "field_order"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "template_fields", ["editable"], name: "index_template_fields_on_editable", using: :btree
  add_index "template_fields", ["slide_template_id"], name: "index_template_fields_on_slide_template_id", using: :btree

  create_table "tickets", force: :cascade do |t|
    t.string   "name",        limit: 255,                     null: false
    t.integer  "status",                  default: 1,         null: false
    t.text     "description",                                 null: false
    t.integer  "event_id"
    t.integer  "about_id"
    t.string   "about_type",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "kind",        limit: 255, default: "request", null: false
  end

  add_index "tickets", ["about_id", "about_type"], name: "index_tickets_on_about_id_and_about_type", using: :btree
  add_index "tickets", ["event_id", "status"], name: "index_tickets_on_event_id_and_status", using: :btree
  add_index "tickets", ["event_id"], name: "index_tickets_on_event_id", using: :btree
  add_index "tickets", ["status"], name: "index_tickets_on_status", using: :btree

  create_table "tokens", force: :cascade do |t|
    t.string   "token"
    t.integer  "access_id"
    t.string   "access_type"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "tokens", ["access_type", "access_id"], name: "index_tokens_on_access_type_and_access_id", using: :btree
  add_index "tokens", ["token"], name: "index_tokens_on_token", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "username",   limit: 50
    t.string   "password",   limit: 50
    t.string   "salt",       limit: 50
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

end
