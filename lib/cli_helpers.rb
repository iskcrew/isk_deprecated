# ISK - A web controllable slideshow system
#
# A library for helper functions for CLI tasks
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


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
		@_connection_id= cid
	end

	def data=(d)
		@_data = d
	end
	
	def to_a
		data = {}
		data['data'] = @_data
		if @_connection_id
			data['connection_id'] = @_connection_id
		end
		return [@_name, data]
	end
end

# TODO: https
def isk_login(host, port, username, password)
	puts "Logging in to ISK at #{host}:#{port}...".green

	# Send a POST request to ISK and collect cookies
	http = Net::HTTP.new(host, port)
	resp, data = http.post('/login', "username=#{username}&password=#{password}&format=json")

	#Check the return code from the POST request
	if resp.is_a? Net::HTTPForbidden
		abort "Error loggin into ISK, aborting".red
	end

	# Extract cookies
	all_cookies = resp.get_fields('set-cookie')
	cookies_array = Array.new
	all_cookies.each { | cookie |
		cookies_array.push(cookie.split('; ')[0])
	}
	cookies = cookies_array.join('; ')

	# Store the session cookie
	headers = {
		'Cookie' => cookies
	}
	
	return http, headers
end