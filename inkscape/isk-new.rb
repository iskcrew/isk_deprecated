# ISK - A web controllable slideshow system
#
# Inkscape plugin for logging in to ISK and creating a new slide
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

require 'optparse'
require 'ostruct'
require 'net/http'
require 'rexml/document'

options = OpenStruct.new
options.username = nil
options.password = nil
options.slidename = nil


OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

	opts.on("-u", "--username username", "ISK username") do |user|
			options.username = user
	end

	opts.on("-p", "--password password", "ISK password") do |pw|
			options.password = pw
	end
	
	opts.on("-n", "--slidename name", "Slide name") do |sn|
			options.slidename = sn
	end

	opts.on("-i", "--iskhost hostname", "ISK hostname") do |host|
			options.host = host
	end

	# Need to specify this even when we don't use the id of selected object
	opts.on("-e", "--id object_id", "Object id") do |id|
			options.id = id
	end

	
end.parse!

http = Net::HTTP.new(options.host)
resp, data = http.post('/login', "username=#{options.username}&password=#{options.password}")
cookie = resp.response['set-cookie'].split('; ')[0]

unless resp.is_a? Net::HTTPFound
	abort "Error loggin into ISK, aborting"
end

headers = {
  'Cookie' => cookie,
 }

 data = "slide[name]=#{options.slidename}"
 data << "&create_type=empty_file"

resp, data = http.post('/slides', data, headers)

unless resp.is_a? Net::HTTPFound
	abort "Error creating slide"
end

if resp.kind_of?(Net::HTTPRedirection)
	if resp['location'].nil?
		slide_url = resp.body.match(/<a href=\"([^>]+)\">/i)[1]
	else
		slide_url = resp['location']
	end
end

slide_id = slide_url.split('/').last.to_i

resp, data = http.get('/slides/' + slide_id.to_s + '/svg_data', headers)

puts resp.body

exit
