# ISK - A web controllable slideshow system
#
# A library for helper functions for CLI tasks
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md
require "rest-client"

def say(msg)
  puts "#{Time.now.strftime('%FT%T%z')}: #{msg}"
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
    @_connection_id = cid
  end

  def data=(d)
    @_data = d
  end

  def to_a
    data = {}
    data["data"] = @_data
    if @_connection_id
      data["connection_id"] = @_connection_id
    end
    return [@_name, data]
  end
end

# TODO: https
def isk_login(host, port, username, password)
  puts "Logging in to ISK at #{host}:#{port}...".green

  base_url = String.new
  # Send a POST request to ISK and collect cookies
  if port.to_i == 443
    base_url = "https://#{host}/"
  else
    base_url = "http://#{host}:#{port}/"
  end
  puts base_url
  r = RestClient.post "#{base_url}/login", { username: username, password: password }, accept: :json

  # Check the return code from the POST request
  if r.code != 200
    abort "Error loggin into ISK, aborting".red
  end

  return base_url, r.cookie_jar
end
