#!/usr/bin/env ruby

# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

# Set up gems listed in the Gemfile.
# ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
# require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

require "highline/import"
require "colorize"
require "faye/websocket"
require "json"
require "time_diff"
require "rest-client"

require_relative "../lib/isk_message.rb"
require_relative "../lib/cli_helpers.rb"

@host = ARGV[0]
@port = ARGV[1]
@port ||= 80

username = ask("Username:  ")
password = ask("Password:  ") { |q| q.echo = "x" }

@base_url, @cookies = isk_login(@host, @port, username, password)
@headers = { "Cookie" => "#{@cookies.cookies.first.name}=#{@cookies.cookies.first.value};" }
# Get list of displays

resp = RestClient.get("#{@base_url}displays", cookies: @cookies, accept: :json)
@displays = JSON.parse resp.body

@connection_opened = Time.now
@ws = nil

@ws_base_url = "ws://#{@host}:#{@port}/"
@ws_base_url = "wss://#{@host}/" if @port.to_i == 443

def init_general_socket
  @ws = Faye::WebSocket::Client.new("#{@ws_base_url}isk_general", nil, headers: @headers)

  @ws.on :open do |event|
    say "General connection opened"
    @connection_opened = Time.now
  end

  @ws.on :message do |event|
    msg = IskMessage.from_json(event.data)
    case msg.type
    when "update"
      say "Update notification: #{msg.object} with id=#{msg.payload[:id]}".yellow
      say " -> Changes: #{msg.payload[:changes]}"
    when "updated_image"
      say "Updated image notification: #{msg.object} with id=#{msg.payload[:id]}".blue
    when "data"
      say "Display data for #{msg.object} id=#{msg.payload[:id]}".light_blue
    when "create"
      say "Create notification: #{msg.object} with id=#{msg.payload[:id]}".white
    else
      say "Got unhandled message: #{msg}".red
    end
  end

  @ws.on :close do |event|
    say "General connection closed!".red
    say "Connection was opened at: #{@connection_opened.strftime('%FT%T%z')}".red
    say "Connection was up for #{Time.diff(Time.now, @connection_opened, '%h:%m:%s')[:diff]}".red
    say "Reconnecting in 10 seconds"
    sleep(10)
    init_general_socket
  end
end

def init_display_socket(id)
  dws = Faye::WebSocket::Client.new("#{@ws_base_url}/displays/#{id}/websocket", nil, headers: @headers)

  opened = Time.now

  dws.on :open do |event|
    say "Display #{id} connection opened"
    opened = Time.now
  end

  dws.on :message do |event|
    msg = IskMessage.from_json(event.data)
    case msg.type
    when "data"
      say "Display data for display id=#{msg.payload[:id]} name=#{msg.payload[:name]}"
    when "current_slide"
      say "Current slide on display: id=#{id}\tslide_id=#{msg.payload[:slide_id]}"
    when "slide_shown"
      say "Slide shown on display:   id=#{id}\tslide_id=#{msg.payload[:slide_id]}"
    when "error"
      say "Error on display: #{id} error=#{msg.payload[:error]}".red
    when "start"
      say "Display #{id} is starting".yellow
    when "shutdown"
      say "Display #{id} is shutting down".yellow
    else
      say "Got unhandled message: #{msg}".red
    end
  end

  dws.on :close do |event|
    say "Display #{id} connection closed!".red
    say "Connection was opened at: #{opened.strftime('%FT%T%z')}".red
    say "Connection was up for #{Time.diff(Time.now, opened, '%h:%m:%s')[:diff]}".red
    say "Reconnecting in 10 seconds"
    sleep(10)
    init_display_socket(id)
  end
end

EM.run do
  init_general_socket
  @displays.each do |d|
    init_display_socket(d["id"])
  end
end
