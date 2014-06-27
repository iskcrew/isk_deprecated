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
	
end
