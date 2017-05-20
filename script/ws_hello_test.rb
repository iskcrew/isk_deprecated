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

require "rubygems"

# Set up gems listed in the Gemfile.
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)
require "bundler/setup" if File.exist?(ENV["BUNDLE_GEMFILE"])
require "highline/import"
require "colorize"
require "faye/websocket"
require "json"

require_relative "../lib/cli_helpers.rb"

abort "Usage: <display_name> <host> [port]" unless ARGV.size >= 2

display_name = ARGV[0]
host = ARGV[1]
port = ARGV[2]
port ||= 80

username = ask("Username:  ")
password = ask("Password:  ") { |q| q.echo = "x" }

_http, headers = isk_login(host, port, username, password)

EM.run do
  ws = Faye::WebSocket::Client.new("ws://#{host}:#{port}/websocket", nil, headers: headers)

  ws.on :open do |event|
    say "Connection opened"
  end

  ws.on :message do |event|
    msg = JSON.parse(event.data).first
    msg_name = msg.first
    msg_hash = msg.last
    msg_channel = msg_hash["channel"]
    case msg_name
    when "client_connected"
      @connection_id = msg_hash["data"]["connection_id"]
      say msg
      say "Connection set: #{msg_hash['data']['connection_id']}"

      # Build the pong reply message
      @pong = WsMessage.new "websocket_rails.pong", nil, @connection_id

      # Start the display handshake by sending iskdpy.hello message
      hello = WsMessage.new "iskdpy.hello", { display_name: display_name }, @connection_id
      say "Sending: #{hello.to_a.to_json}"
      ws.send hello.to_a.to_json

    when "iskdpy.hello"
      # The iskdpy.hello should return success and the display data
      if msg_hash["success"] == true
        say "iskdpy.hello succesful"
        data = msg_hash["data"]
        say "Display state:"
        say "Name: #{data['name']} ID: #{data['id']}"
        say "Manual mode: #{data['manual'] ? 'Yes' : 'No'}"
        say "Presentation: #{data['presentation']['name']}"
        say " -> id: #{data['presentation']['id']}"
        say "Current group id: #{data['current_group_id']}"
        say "Current slide id: #{data['current_slide_id']}"
        say "Slides in override queue: #{data['override_queue'].size}"
      else
        say "iskdpy.hello unsuccesful, got reply:"
        puts JSON.pretty_generate JSON.parse(event.data)
        abort "exiting"
      end

    when "websocket_rails.subscribe"

    when "websocket_rails.ping"
      ws.send @pong.to_a.to_json

    when "update"
      say "Update notification: #{msg_channel} with id=#{msg_hash['data']['id']}"

    when "data"
      d = msg_hash["data"]
      say "Display data for display id=#{d['id']}"

    else
      say "Got unhandled message: "
      say event.data
      if msg_channel
        say " -> Channel: #{msg_channel} message: #{msg_name} hash: #{msg_hash}"
      end
    end
  end

  ws.on :close do |event|
    say [:close, event.code, event.reason]
    ws = nil
  end
end
