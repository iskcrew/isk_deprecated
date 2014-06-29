require 'test_helper'

class TicketsControllerTest < ActionController::TestCase
	def setup
		@adminsession = {user_id: users(:admin).id, username: users(:admin).username}
		@new_ticket_data = {
			ticket: {
				name: 'New test ticket',
				description: "Ticket test\ndescription\nhere",
				object_type: 'slide',
				object_id: slides(:no_clock).id
			}
		}
	end
	
	test "get index" do
		get :index, nil, @adminsession
		assert_response :success, "Failed to get tickets list as admin"
	end
	
	test "get ticket info" do
		[
			:slide_ticket, :master_group_ticket, :presentation_ticket, :closed_ticket
		].each do |t|
			get :show, {id: tickets(t)}, @adminsession
			assert_response :success, "Failed to get info for ticket #{t} as admin"
		end
	end
	
	test "create new ticket" do
		get :new, nil, @adminsession
		assert_response :success
		
		assert_difference('Ticket.count', 1) do
			post :create, @new_ticket_data, @adminsession
		end
		
		assert_redirected_to ticket_path(assigns(:ticket)), "Didn't redirect to ticket page"
		assert_equal @new_ticket_data[:ticket][:name], assigns(:ticket).name, "Ticket didn't have correct name"
		assert assigns(:ticket).about.present?
		assert assigns(:ticket).about.is_a? Slide
		assert assigns(:ticket).about_id == @new_ticket_data[:ticket][:object_id]
	end
	
	test "try to create invalid ticket" do
		assert_no_difference('Ticket.count') do
			post :create, {ticket: {name: 'Invalid'}}, @adminsession
			assert_template :new
		end
	end
	
	test "update ticket" do
		get :edit, {id: tickets(:presentation_ticket).id}, @adminsession
		assert_response :success
		
		put :update, {id: tickets(:presentation_ticket).id, ticket: {description: 'Updated'}}
		assert_redirected_to ticket_path(assigns(:ticket))
		assert_equal 'Updated', assigns(:ticket).description
		assert_equal Ticket::StatusOpen, assigns(:ticket).status
	end
	
	test "try to update invalid ticket" do
		put :update, {id: tickets(:open_ticket), ticket: {name: ''}}, @adminsession
		assert_template :edit
	end
	
end
