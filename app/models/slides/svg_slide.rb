# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class SvgSlide < Slide
	
	TypeString = 'svg-edit'

	@_svg_data = nil
	
	before_create do |slide|
		slide.is_svg = true
		true
	end

	
	def generate_full_image
		tmp_file = Tempfile.new('isk-image')
		output = `#{inkscape_command_line(tmp_file)}`
		if $?.to_i == 0
			return compare_new_image(tmp_file)
		else
			raise Slide::ImageError, "Error converting the slide svg into PNG\nInkscape output:\n#{output}"
		end
	end

end
