# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class InkscapeSlide < SvgSlide
	# Constants
	# Slide type to report in html views
	TypeString = 'inkscape'
	
	before_create do |slide|
		slide.is_svg = true
		true
	end

	def self.copy!(s)
		orig_id = s.id

		ink = s.dup
		ink.save!
		ink.reload

		FileUtils.copy(s.svg_filename, ink.svg_filename)

		ink.to_inkscape_slide!

		ink = InkscapeSlide.find(ink.id)

		s = Slide.find(orig_id)
		s.replacement_id = ink.id

		return ink
	end

	# Create a new InkscapeSlide from a SimpleSlide
	def self.create_from_simple(simple_slide)
		raise ApplicationController::ConvertError unless simple_slide.is_a? SimpleSlide
		
		ink = InkscapeSlide.new
		ink.name = "#{simple_slide.name} (converted)"
		ink.description = "Converted from a simple slide #{simple_slide.name} at #{I18n.l Time.now, format: :short}"
		ink.ready = false
		ink.svg_data = simple_slide.svg_data
		ink.save!
		ink.generate_images_later
		return ink
	end

	# We carry the slide id in a metadata tag
	# This is used by the inkscape plugins
	# TODO: verification cookie?
	# FIXME: Use a better id and sync with plugins!
	def update_metadata!
		svg = Nokogiri::XML(self.svg_data)
		svg = metadata_contents(svg)

		File.open(self.svg_filename, 'w') do |f|
			f.write svg.to_xml
		end
	end

	protected

	def metadata_contents(svg)
		svg.css('metadata').each do |meta|
			meta.remove
		end
		metadata = Nokogiri::XML::Node.new 'metadata', svg
		metadata['id'] = 'metadata1'
		meta = "#{self.id}!depricated.invalid.com"
		metadata.content = meta
		svg.root.add_child metadata
		return svg
	end

	private
end

# Require all STI children, this needs to be done so that InkscapeSlide.count et al select all inherited types
require_dependency 'template_slide'
