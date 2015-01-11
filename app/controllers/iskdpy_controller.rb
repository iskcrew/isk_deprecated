# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class IskdpyController < WebsocketRails::BaseController
	
	# Wrap calls into ActiveSupport::Notifications for logging
	around_action :instrument_action
	
	# Work-around for websocket-rails issue #228
	include ClearQueryCache
	
	# The display calls this when initializing to get the inital data
	# and to add a new display to the db if need be
	# message[:display_name] should contain the unique display name
	def hello
		unless d = Display.where(:name => message[:display_name]).first and require_display_control(d)
			trigger_failure forbidden_message
			return
		end
		
		d = Display.hello(message[:display_name], origin_ip, connection.id)
		trigger_success d.to_hash
	end
	
	# The display informs us about its current slide
	def current_slide
		d = Display.find(message[:display_id])
		
		unless require_display_control(d)
			trigger_failure forbidden_message
			return
		end
		
		if message[:override_queue_id]
			ret = d.override_shown(message[:override_queue_id], connection.id)
		else
			ret = d.set_current_slide(message[:group_id], message[:slide_id], connection.id)
		end
		
		if ret == false
			# Setting the current slide failed
			data = {display_id: d.id, message: 'Invalid slide specified'}
			trigger_failure data
		else
			data = {:display_id => d.id, :group_id => d.current_group_id, :slide_id => d.current_slide_id}
			WebsocketRails[d.websocket_channel].trigger(:current_slide, data)
			trigger_success data
		end
	end
	
	# Send a message instructing a display to go to a specific slide
	def goto_slide
		d = Display.find(message[:display_id])
		
		unless d.can_edit?(current_user)
			trigger_failure forbidden_message
			return
		end
		
		data = message
		WebsocketRails[d.websocket_channel].trigger(:goto_slide, data)
		trigger_success data
	end
			
	# Send the serialization of a display
	def display_data
		d = Display.find(message[:display_id])
		data = d.to_hash
		trigger_success data
	end
	
	# Handle a error report from the display
	def display_error
		d = Display.find(message[:display_id])
		
		unless require_display_control(d)
			trigger_failure forbidden_message
			return
		end
		
		d.add_error message[:error]
		d.save!
	end
	
	# A display is shutting down due to user request.
	# The following disconnect won't be because of error
	def shutdown
		Display.disconnect(connection.id)
	end
	
	# A websocket-client disconnects, we need to check if it was a display and update its state if so.
	def client_disconnect
		d = Display.joins(:display_state).where(display_states: {websocket_connection_id: connection.id}).first
		if d.present?
			d.add_error 'Connection lost!'
			d.save!
		end
	end
	
	private
	
	# Find out the origin ip for the request
	def origin_ip
		if connection.request.headers['HTTP_X_FORWARDED_FOR']
			connection.request.headers['HTTP_X_FORWARDED_FOR']
		else
			connection.request.remote_ip
		end
	end
	
	# Instrument all controller actions
	# This is used by the lib/display_logging.rb to log stuff
	def instrument_action
		ActiveSupport::Notifications.instrument('iskdpy', 
			action: action_name, client: client_id, ip: origin_ip, message: message) do
			yield
		end
	end
	
	def require_display_control(display)
		current_user.has_role?('display-client') or display.can_edit?(current_user)
	end
	
	def forbidden_message
		{message: 'Forbidden'}
	end
	
end
