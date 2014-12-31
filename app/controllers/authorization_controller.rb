# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class AuthorizationController < WebsocketRails::BaseController
	
	# Check that the user has logged in when new websocket connection is opened
	# If the user is missing we will call on_error on the connection and thus close it.
	def new_connection
		unless current_user.present?
			connection.close!
		end
	end
	
end