# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

class SvgController < WebsocketRails::BaseController
	# This is a controller for svg related websocket actions

	# Generate the svg for a simple slide, used for the browser preview
	def simple
		svg = SimpleSlide.create_svg(message[:simple])
		trigger_success svg
	end
	
	# Generate the svg for a templateslide, used for the browser preview
	def template
		svg = SlideTemplate.find(message[:template_id]).generate_svg(message)
		trigger_success svg
	end
end
