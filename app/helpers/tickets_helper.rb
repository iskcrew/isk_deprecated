#
#  tickets_helper.rb
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-06-27.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#

module TicketsHelper
	
	# Link to the object associated to this ticket
	def ticket_concerning(ticket)
		if ticket.about.present?
			return "#{ticket.about_type.capitalize}: #{ticket_object_link(ticket)}".html_safe
		else
			return "None"
		end
	end
	
	# Render a link to the associated object on a ticket
	def ticket_object_link(ticket)
		if ticket.about.is_a? Slide
			url = slide_path(ticket.about)
		elsif ticket.about.is_a? Presentation
			url = presentation_path(ticket.about)
		elsif ticket.about.is_a? MasterGroup
			url = group_path(ticket.about)
		elsif ticket.about.is_a? Display
			url = display_path(ticket.about)
		end
		return link_to ticket.about.name, url
	end
	
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
	
	# A bootstrap badge for the ticket status
	def ticket_status(ticket)
		case ticket.status
		when Ticket::StatusNew
			html_class = "label-danger"
		when Ticket::StatusOpen
			html_class = "label-warning"
		else
			html_class = "label-success"
		end
		content_tag 'span', class: "label #{html_class}" do
			ticket.status_text
		end
	end
	
	def ticket_edit_link(ticket)
		if ticket.can_edit? current_user
			link_to icon('edit', 'Edit'), edit_ticket_path(ticket), class: 'btn btn-primary'
		end
	end
	
	def ticket_close_link(ticket)
		if ticket.can_close? current_user
			link_to icon('check-square-o', 'Close'), 
				ticket_path(ticket, ticket: {status: Ticket::StatusClosed}), 
				class: 'btn btn-warning', method: :put
		end
	end
	
	def ticket_destroy_link(ticket)
		if ticket.admin? current_user
			link_to icon('times-circle', 'Delete'), 
				ticket_path(ticket), class: 'btn btn-danger', method: :delete,
				data: {confirm: 'Are you sure you want to permanently delete this ticket?'}
		end
	end
	
	def ticket_tab_link(open)
		link_name = "Tickets <span class=badge>#{icon 'ticket', open}</span>"
		return link_to link_name.html_safe, tickets_path, class: 'ui-tabs-anchor'
	end
	
	def ticket_kind(ticket)
		case ticket.kind
		when 'error'
			content_tag 'span', class: 'label label-danger' do
				icon('warning', ticket.kind.capitalize)
			end
		else
			content_tag 'span', class: 'label label-info' do
				ticket.kind.capitalize
			end
		end
	end
	
	private
	
	def ticket_open_count
		if Ticket.current.open.count > 0
			html = icon 'ticket'
			html << Ticket.ticket.open.count.to_s
			return html
		else
			return ""
		end
	end
	
end
