# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class ScheduleSlide < Slide
	#Automatically generated schedule slide
	TypeString = 'schedule'

	before_create do |slide|
		slide.is_svg = true
		true
	end

	private

	# Override the default image generator
	# FIXME: make inkscape the default for everyone and remove this
	def generate_full_image
		system inkscape_command_line
	end

end