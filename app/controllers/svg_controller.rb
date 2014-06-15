# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class SvgController < WebsocketRails::BaseController
	# This is a controller for svg related websocket actions
	# Currently we only support generating a new svg with
	# the simple_slide svg generator
	
	def simple
		svg = SimpleSlide.create_svg(message[:simple])
		trigger_success svg
	end
	
	def template
		svg = SlideTemplate.find(message[:template_id]).generate_svg(data)
		trigger_success svg
	end


end