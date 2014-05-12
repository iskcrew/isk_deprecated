#!/usr/bin/env ruby

# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

# A simple utility for testing the display handshake
# Opens a websocket connection and then reports the results of the hand-shake
# USAGE:
# ws_hello_test.rb <host> <display_name>
#
# Example:
# ws_hello_test.rb localhost:3000 test_display

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', 'environment'))

unless ARGV.size == 2
	abort "Usage: <host> <display_name>"
end
	

host = ARGV.first
display_name = ARGV.last

def say(msg)
	puts "#{Time.now.strftime('%FT%T%z')}: #{msg}"
end

@connection_id = nil
@channels = [
	'slide',
	'master_group',
	'group',
	'presentation',
	'display',
	'override_queue',
	'display_state'
]

Display.all.each do |d|
	@channels << d.websocket_channel
end

class WsMessage
	def initialize(name, data, con_id = nil)
	    @_name = name
			@_data = data
			@_connection_id = con_id
			return self
	end


	def name=(n)
		@_name = n
	end
	
	def connection_id=(cid)
		@_connection_id= cid
	end

	def data=(d)
		@_data = d
	end
	
	def to_a
		data = {}
		data['data'] = @_data
		return [@_name, data, @_connection_id]
	end

end


EM.run {
  ws = Faye::WebSocket::Client.new("ws://#{host}/websocket")

  ws.on :open do |event|
    say 'Connection opened'
  end

  ws.on :message do |event|
    msg = JSON.parse(event.data).first
		msg_name = msg.first
		msg_hash = msg.last
		msg_channel = msg_hash['channel']
		case msg_name
		when 'client_connected'
			@connection_id = msg_hash['data']['connection_id']
			say msg
			say "Connection set: #{msg_hash['data']['connection_id']}"
			
			# Build the pong reply message
			@pong = WsMessage.new 'websocket_rails.pong', nil, @connection_id
			
			# Start the display handshake by sending iskdpy.hello message
			hello = WsMessage.new 'iskdpy.hello', {display_name: display_name}, @connection_id
			say "Sending: #{hello.to_a.to_json}" 
			ws.send hello.to_a.to_json 
			
		when 'iskdpy.hello'
			# The iskdpy.hello should return success and the display data
			if msg_hash['success'] == true
				say 'iskdpy.hello succesful'
				data = msg_hash['data']
				say 'Display state:'
				say "Name: #{data['name']} ID: #{data['id']}"
				say "Manual mode: #{data['manual'] ? 'Yes' : 'No'}"
				say "Presentation: #{data['presentation']['name']}"
				say " -> id: #{data['presentation']['id']}"
				say "Current group id: #{data['current_group_id']}"
				say "Current slide id: #{data['current_slide_id']}"
				say "Slides in override queue: #{data['override_queue'].size}"
				
			else
				say 'iskdpy.hello unsuccesful, got reply:'
				say event.data
				abort 'exiting'
			end
			
		when 'websocket_rails.subscribe'
			
			
		when 'websocket_rails.ping'
			ws.send @pong.to_a.to_json
		
		when 'update'
			say "Update notification: #{msg_channel} with id=#{msg_hash['data']['id']}"
			
		when 'data'
			d = msg_hash['data']
			say "Display data for display id=#{d['id']}"
		
		else
			say 'Got unhandled message: '
			say event.data
			if msg_channel
				say " -> Channel: #{msg_channel} message: #{msg_name} hash: #{msg_hash}"
			else
			end
		end
	
  end

  ws.on :close do |event|
    say [:close, event.code, event.reason]
    ws = nil
  end
}
