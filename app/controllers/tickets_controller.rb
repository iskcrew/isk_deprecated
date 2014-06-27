class TicketsController < ApplicationController
	
	def index
		@tickets = Ticket.current
	end
	
	def new
		@ticket = Ticket.new
	end
	
	def create
		@ticket = Ticket.new(ticket_params)
		
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
