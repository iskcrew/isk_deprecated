# frozen_string_literal: true
class CreateDisplayStates < ActiveRecord::Migration
  def up
    create_table :display_states do |t|
      t.references :display
      t.integer  "current_group_id"
      t.integer  "current_slide_id"
      t.datetime "last_contact_at"
      t.datetime "last_hello"
      t.integer  "websocket_connection_id"
      t.string   "ip",                      limit: 12
      t.boolean  "monitor",                 default: true
      t.timestamps
    end

    Display.all.each do |d|
      ds = DisplayState.new
      ds.current_group_id         = d.read_attribute("current_group_id")
      ds.current_slide_id         = d.read_attribute("current_slide_id")
      ds.last_contact_at          = d.read_attribute("last_contact_at")
      ds.last_hello               = d.read_attribute("last_hello")
      ds.websocket_connection_id  = d.read_attribute("websocket_connection_id")
      ds.ip                       = d.read_attribute("ip")
      ds.monitor                  = d.read_attribute("monitor")
      ds.save!
      d.display_state = ds
    end

    change_table :displays do |t|
      t.remove :current_group_id
      t.remove :current_slide_id
      t.remove :last_contact_at
      t.remove :last_hello
      t.remove :websocket_connection_id
      t.remove :ip
      t.remove :monitor
      t.remove :metadata_updated_at
    end
  end

  def down
    change_table :displays do |t|
      t.integer  "current_group_id"
      t.integer  "current_slide_id"
      t.datetime "last_contact_at"
      t.datetime "last_hello"
      t.datetime "metadata_updated_at"
      t.integer  "websocket_connection_id"
      t.string   "ip",                      limit: 12
      t.boolean  "monitor",                 default: true
    end

    Display.all.each do |d|
      d.write_attribute("current_group_id",         d.display_state.current_group_id)
      d.write_attribute("current_slide_id",         d.display_state.current_slide_id)
      d.write_attribute("last_contact_at",          d.display_state.last_contact_at)
      d.write_attribute("last_hello",               d.display_state.last_hello)
      d.write_attribute("websocket_connection_id",  d.display_state.websocket_connection_id)
      d.write_attribute("ip",                       d.display_state.ip)
      d.write_attribute("monitor",                  d.monitor)
      d.metadata_updated_at = d.updated_at
      d.save!
    end

    drop_table :display_states
  end
end
