# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md
#
# A general module for all models that support opening tickets on them

module	HasTickets
	extend ActiveSupport::Concern
	
	included do
		has_many :tickets, as: :about
	end
	
	# Define class methods for the model including this
	module ClassMethods
		
		# Return all records with error tickets
		def with_error_tickets
			self.joins(:tickets)
			.where(tickets: {kind: 'error'})
			.where.not(tickets: {status: Ticket::StatusClosed})
		end
	end
	
	# Add a new error ticket on this object with given message
	def add_error_ticket(message)
		t = Ticket.new(kind: 'error')
		t.about = self
		t.name = "Error in #{self.class.name}: #{self.name}"
		t.description = message
		t.save!
	end
	
	def error_tickets
		self.tickets.where(kind: 'error')
	end
	
end