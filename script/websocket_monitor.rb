#!/usr/bin/env ruby

# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'highline/import'
require 'colorize'
require 'faye/websocket'
require 'json'

require_relative '../lib/cli_helpers.rb'

host = ARGV[0]
port = ARGV[1]
port ||= 80

username = ask('Username:  ')
password = ask("Password:  ") { |q| q.echo = 'x' }

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

http, headers = isk_login(host, port, username, password)

# Get list of displays
resp, data = http.get('/displays?format=json', headers)
displays = JSON.parse resp.body
 
displays.each do |d|
	@channels << "display_#{d['id']}"
end

@connection_opened = Time.now

EM.run {
	ws = Faye::WebSocket::Client.new("ws://#{host}:#{port}/websocket", nil, headers: headers)

	ws.on :open do |event|
		say 'Connection opened'
		@connection_opened = Time.now
	end

	ws.on :message do |event|
		msg = JSON.parse(event.data).first
		msg_name = msg.first
		msg_hash = msg.last
		msg_channel = msg_hash['channel']
		case msg_name
		when 'client_connected'
			@connection_id = msg_hash['data']['connection_id']
			say "Connection set: #{msg_hash['data']['connection_id']}"
			
			@pong = WsMessage.new 'websocket_rails.pong', nil, @connection_id
			
			say 'Subscribing to channels:'
			@channels.each do |c|
				sub = WsMessage.new 'websocket_rails.subscribe', {channel: c}
				say " -> #{c}"
				ws.send sub.to_a.to_json
			end
			
		when 'websocket_rails.subscribe'
			
			
		when 'websocket_rails.ping'
			ws.send @pong.to_a.to_json
		
		when 'websocket_rails.channel_token'
			say 'FIXME: channel tokens!'.red
		
		when 'update'
			say "Update notification: #{msg_channel} with id=#{msg_hash['data']['id']}".yellow
		
		when 'updated_image'
			say "Update image notification: #{msg_channel} with id=#{msg_hash['data']['id']}".blue
			
		when 'data'
			d = msg_hash['data']
			say "Display data for display id=#{d['id']}".light_blue
		
		when 'current_slide'
			d = msg_hash['data']
			say "Display current slide update, display: #{d['display_id']}, slide: #{d['slide_id']}, group: #{d['group_id']}".cyan
		when 'error'
			d = msg_hash['data']
			say "ERROR: Channel: \"#{msg_channel}\" Display: #{d['display_id']}, message #{d['message']}".red
		else
			say 'Got unhandled message: '
			if msg_channel
				say " -> Channel: #{msg_channel} message: #{msg_name} hash: #{msg_hash}".yellow
			else
				say " -> Message: #{msg_name} success: #{msg_hash['success']} data: #{msg_hash['data']}".yellow
			end
		end
	
	end

	ws.on :close do |event|
		say 'Connection closed!'.red
		say "Connection was opened at: #{@connection_opened.strftime('%FT%T%z')}".red
		say "Connection was up for #{Time.diff(Time.now, @connection_opened, "%h:%m:%s")[:diff]}".red
		abort
	end
}
