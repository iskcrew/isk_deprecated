# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


module DisplaysHelper
    
		
  def late_display_warning(d)
    link_text = (d.name || String.new) << " (" << d.ip << ") is more than " << Display::Timeout.to_s << " minutes late!"
    link_to link_text, :controller => :displays, :action => :show, :id => d.id
  end
	
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
		
    
    return content_tag(:span, 'Ping: ' + ping_seconds.to_s + " s.", :class => html_class)
    
  end
  
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
  
  def display_last_contact(d)
    if d.last_contact_at
			delta = Time.diff(Time.now, d.last_contact_at, "%h:%m:%s")[:diff]
			return "#{l d.last_contact_at, format: :short} (#{delta} ago)"
    else
      return 'UNKNOWN'
    end
  end
  
  
end
