# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


module DisplaysHelper
		
	# Links to the details for all late displays
	def late_display_warning(d)
		link_text = "#{d.name} (#{d.ip}) is more than #{Display::Timeout} minutes late!"
		link_to link_text, display_path(d)
	end
	
	# Render the display ping element
	def display_ping(d)
		if d.late?
			html_class = 'late'
		else
			html_class = 'on_time'
		end
		
		if d.last_contact_at
			ping_seconds = (Time.now - d.last_contact_at).to_i

			if ping_seconds > 60
				ping_seconds = ">60"
			end
		else
			ping_seconds = "UNKNOWN"
		end
		
		return content_tag(:span, "Ping: #{ping_seconds} s.", class: html_class)
	end
	
	# Render the img element for the current slide image
	def display_current_slide(d)
		if d.current_slide
			
			html_options = {
				:title => 'Click to show display details',
				:class => 'slide_preview'
			}
			return link_to slide_preview_image_tag(d.current_slide), display_path(d), html_options
		else
			return 'UNKNOWN'
		end
	end
	
	# Render the last_contact_at timestamp and the diff to current time
	def display_last_contact(d)
		if d.last_contact_at
			delta = Time.diff(Time.now, d.last_contact_at, "%h:%m:%s")[:diff]
			return "#{l d.last_contact_at, format: :short} (#{delta} ago)"
		else
			return 'UNKNOWN'
		end
	end
	
end
