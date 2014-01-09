# ISK - A web controllable slideshow system
#
# Modify websocket-rails gem so that pongs from displays
# update our timestamps
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


module  WebsocketRails
  InternalController.class_eval do
    def do_pong
      connection.pong = true
      DisplayState.where(:websocket_connection_id => connection.id).update_all(:last_contact_at => Time.now)
    end
  end
end