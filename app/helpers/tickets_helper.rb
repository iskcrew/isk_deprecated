#
#  tickets_helper.rb
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-06-27.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#

module TicketsHelper
	
	# Render the text of the referenced isk object for views
	def ticket_object_type(obj)
		if obj.is_a? Slide
			'slide'
		elsif obj.is_a? Presentation
			'presentation'
		elsif obj.is_a? MasterGroup
			'group'
		end
	end
	
	def ticket_close_link(ticket)
		link_to 'Close', ticket_path(ticket, ticket: {status: Ticket::StatusClosed}), 
			class: 'button warning', method: :put
	end
	
	def ticket_tab_link
		link_name = "Tickets #{ticket_open_count}"
		return link_to link_name.html_safe, tickets_path, class: 'ui-tabs-anchor'
	end
	
	private
	
	def ticket_open_count
		if Ticket.open.count > 0
			html = icon 'ticket'
			html << Ticket.open.count.to_s
			return html
		else
			return ""
		end
	end
	
end
