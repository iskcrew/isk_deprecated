class TicketsController < ApplicationController
	
	def index
		respond_to do |format|
			format.html {@tickets = Ticket.current}
			format.js {
				@open_tickets = Ticket.current.open.count
			}
		end
	end
	
	def new
		@ticket = Ticket.new
	end
	
	def create
		@ticket = Ticket.new(ticket_create_params)
		
		if @ticket.save
			flash[:notice] = "Ticket created."
			
			# Allow the user creating the ticket edit priviledges if needed
			unless @ticket.can_edit? current_user
				@ticket.authorized_users << current_user
			end
			redirect_to ticket_path(@ticket)
		else
			flash[:error] = "Error saving ticket."
			render :new
		end
	end
	
	def show
		@ticket = Ticket.current.find(params[:id])
	end
	
	def edit
		@ticket = Ticket.current.find(params[:id])
		require_edit @ticket
	end
	
	def update
		@ticket = Ticket.current.find(params[:id])
		require_edit @ticket
		
		if @ticket.update_attributes(ticket_update_params)
			flash[:notice] = "Ticket was succesfully updated."
			redirect_to ticket_path(@ticket)
		else
			flash[:error] = "Error updating ticket."
			render :edit
		end
	end
	
	# Delete a ticket
	def destroy
		# Require that the user has admin powers for tickets.
		require_admin
		
		ticket = Ticket.find(params[:id])
		ticket.destroy
		flash[:notice] = "Ticket has been deleted."
		redirect_to tickets_path
	end
	
	private
	
	# Whitelist mass assignment parameters, only some users can close the tickets
	def ticket_update_params
		if Ticket.admin? current_user
			params.required(:ticket).permit(:name, :description, :status)
		else
			params.required(:ticket).permit(:name, :description)
		end
	end
	
	def ticket_create_params
		params.required(:ticket).permit(:name, :description, :about_type, :about_id)
	end
	
	def require_admin
		unless Ticket.admin? current_user
			raise ApplicationController::PermissionDenied
		end
	end
	
end
