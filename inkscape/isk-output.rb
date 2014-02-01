# ISK - A web controllable slideshow system
#
# ISK export plugin for inkscape, allows for one-click
# exporting the slide back to the server
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

svg_data = File.read(ARGV.last)

xml = REXML::Document.new svg_data

metadata = REXML::XPath.first( xml, "//metadata" )
data = metadata.text


REXML::XPath.each( xml, '//image[@id="background_picture"]' ) do |element|
	href = element.attribute('xlink:href').to_s
	element.add_attribute 'xlink:href', 'backgrounds' + href.partition('backgrounds').last
end

id, isk_server = data.split('!')

post_svg = String.new
xml.write post_svg

resp, data = http.post '/slides/' << id << '/svg_data',{'svg' => post_svg}

puts svg_data