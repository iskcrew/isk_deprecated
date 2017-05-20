# frozen_string_literal: true
class AddWebsocketConnectionIdToDisplays < ActiveRecord::Migration
  def change
    add_column :displays, :websocket_connection_id, :integer, default: nil
  end
end
