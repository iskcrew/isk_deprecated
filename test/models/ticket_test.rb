require 'test_helper'

class TicketTest < ActiveSupport::TestCase
	
	def setup
		# Nimimal valid ticket fields
		@ticket_fields = {
			name: 'Test',
			description: 'Test this ticket'
		}
	end
	
	test "create tickets" do
		ticket = Ticket.new(name: 'Test Ticket')
		assert_not ticket.save, "Saved ticket without description"
		
		ticket.description = "This ticket now has some content"
		assert ticket.save
		assert_equal Ticket::StatusNew, ticket.status, "Ticket didn't have 'open' as its status"
	end
	
	test "update ticket" do
		[:slide_ticket, :new_ticket, :closed_ticket].each do |t|
			ticket = tickets(t)
			ticket.description = "Updated"
			assert ticket.save, "Saving the ticket #{t} failed: #{ticket.errors.messages}"
			assert_equal Ticket::StatusOpen, ticket.status, "Ticket #{ticket} didn't get Open status on update"
		end
	end
	
	test "set ticket status" do
		[:presentation_ticket, :new_ticket, :open_ticket].each do |t|
			ticket = tickets(t)
			ticket.status = Ticket::StatusClosed
			assert ticket.save, "Saving the ticket #{t} failed"
			assert_equal Ticket::StatusClosed, ticket.status, "Ticket #{t} didn't get Closed status on update"
		end
		
		ticket = tickets(:closed_ticket)
		ticket.status = Ticket::StatusClosed
		assert ticket.save, "Saving closed ticket failed"
		assert_equal Ticket::StatusOpen, ticket.status, "Closed ticket should get reopened always"
	end
	
	test "status text" do
		assert_equal 'new', tickets(:new_ticket).status_text
		assert_equal 'open', tickets(:open_ticket).status_text
		assert_equal 'closed', tickets(:closed_ticket).status_text
	end
	
	test "create ticket with forbidden object" do
		ticket = Ticket.new(@ticket_fields)
		ticket.about = Ticket.last
		assert_not ticket.save, "Saved a ticket about a ticket"
	end
	
	test "create ticket about a slide" do
		ticket = Ticket.new(@ticket_fields)
		ticket.about = Slide.last
		assert ticket.save, "Error saving a ticket about a slide"
	end
	
	test "create ticket about a presentation" do
		ticket = Ticket.new(@ticket_fields)
		ticket.about = Presentation.last
		assert ticket.save, "Error saving a ticket about a presentation"
	end
	
	test "create ticket about a master group" do
		ticket = Ticket.new(@ticket_fields)
		ticket.about = MasterGroup.last
		assert ticket.save, "Error saving a ticket about a master_group"
	end

end
