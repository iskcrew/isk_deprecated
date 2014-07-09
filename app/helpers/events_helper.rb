# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


module EventsHelper
	
	# Select box for choosing the slide resolution for the event.
	def event_slide_resolution_select(event)
		resolutions = Event::SupportedResolutions
		options = resolutions.collect.with_index do |r, i|
			["#{r.first} x #{r.last}", i]
		end
		
		selected = resolutions.index event.picture_sizes[:full]
		
		return select_tag(:resolution, options_for_select(options, selected) )
	end
end
