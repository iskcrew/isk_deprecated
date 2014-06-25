# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


module PresentationsHelper
	
	# Convert the slide duration from seconds into human readable format
	# FIXME: namespace this properly
	def duration_to_text(dur)
		(Time.mktime(0)+dur).strftime("%H:%M:%S")
	end

end
