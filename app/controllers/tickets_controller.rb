class TicketsController < ApplicationController
	
	def index
		@tickets = Ticket.current
	end
	
	def new
		@ticket = Ticket.new
	end
	
	def create
		@ticket = Ticket.new(ticket_params)
		
		# Associate to object if needed
		case params[:ticket][:object_type]
		when 'slide'
			@ticket.about = Slide.find(params[:ticket][:object_id])
		when 'presentation'
			@ticket.about = Presentation.find(params[:ticket][:object_id])
		when 'group'
			@ticket.about = MasterGroup.find(params[:ticket][:object_id])
		end
		
		if @ticket.save
			flash[:notice] = "Ticket created."
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
	end
	
	def update
		@ticket = Ticket.current.find(params[:id])
		if @ticket.update_attributes(ticket_params)
			flash[:notice] = "Ticket was succesfully updated."
			redirect_to ticket_path(@ticket)
		else
			flash[:error] = "Error updating ticket."
			render :edit
		end
	end
	
	private
	
	def ticket_params
		params.required(:ticket).permit(:name, :description, :status)
	end
	
end
