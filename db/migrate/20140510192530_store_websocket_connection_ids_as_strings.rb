class StoreWebsocketConnectionIdsAsStrings < ActiveRecord::Migration
  def up
    change_column :display_states, :websocket_connection_id, :string
  end

  def down; end
end
