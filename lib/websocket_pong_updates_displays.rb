module  WebsocketRails
  InternalController.class_eval do
    def do_pong
      connection.pong = true
      Display.where(:websocket_connection_id => connection.id).update_all(:last_contact_at => Time.now)
    end
  end
end