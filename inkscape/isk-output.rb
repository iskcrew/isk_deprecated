#Tungetaan kuva ISK:hon!
require 'net/http'
require 'rexml/document'

isk_server = 'http://isk:Kissa@isk.depili.fi'

svg_data = File.read(ARGV.last)

xml = REXML::Document.new svg_data

metadata = REXML::XPath.first( xml, "//metadata" )
data = metadata.text


bg = REXML::XPath.each( xml, '//image[@id="background_picture"]' ) do |element|
	href = element.attribute('xlink:href').to_s
	element.add_attribute 'xlink:href', 'backgrounds' + href.partition('backgrounds').last
end

id, isk_server = data.split('!')

post_svg = String.new
xml.write post_svg

res = Net::HTTP.post_form(URI.parse(isk_server << '/slides/' << id << '/svg_data'),{'svg' => post_svg})

puts svg_data