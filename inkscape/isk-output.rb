# ISK - A web controllable slideshow system
#
# ISK export plugin for inkscape, allows for one-click
# exporting the slide back to the server
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

require "optparse"
require "ostruct"
require "net/http"
require "rexml/document"

options = OpenStruct.new
options.username = nil
options.password = nil
options.slidename = nil

# Per the .inx extension definition we will get the following command-line parameters:
# --username for the ISK login username
# --password for the ISK password
# --iskhost for the ISK address
# last argument given will be the location for a file with the svg data in it.
# inkscape also returns the selected item's svg-id with --id command line parameter
# but we don't care about it

# Parse the command line options
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

# Send a POST request to ISK and collect cookies
http = Net::HTTP.new(options.host)
resp, data = http.post("/login", "username=#{options.username}&password=#{options.password}")
cookie = resp.response["set-cookie"].split("; ")[0]

#Check the return code from the POST request
unless resp.is_a? Net::HTTPFound
  abort "Error loggin into ISK, aborting"
end

# Store the session cookie
headers = {
  "Cookie" => cookie,
 }

# Read the svg data from the file provided in command line arguments
svg_data = File.read(ARGV.last)

xml = REXML::Document.new svg_data

#Find the first <metadata> element in the svg document
metadata = REXML::XPath.first(xml, "//metadata")
data = metadata.text

# The metadata-element contains a cookie about the origin, it's in the form of slide_id!isk_host
# so for example 123!http://example.com/ we don't care about the legacy url anymore, so just take
# the id
id, isk_server = data.split("!")

# Inkscape chances the background picture from relative to absolute path, so we
# need to change it back. The path will be something like c:/foo/bar/background/empty.png
# and we want /backgrounds/empty, so match on backgrounds and mangle based on that.
REXML::XPath.each(xml, '//image[@id="background_picture"]') do |element|
  href = element.attribute("xlink:href").to_s
  element.add_attribute "xlink:href", "backgrounds#{href.partition("backgrounds").last}"
end

# Write the modified svg into a string
post_svg = String.new
xml.write post_svg

# post the svg data to ISK
resp, data = http.post "/slides/#{id}/svg_data", { "svg" => post_svg }, headers

# Inkscape expects the plugin to return the svg in stdout, so do so
puts svg_data
