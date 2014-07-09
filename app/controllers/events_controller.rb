# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

class EventsController < ApplicationController
	# This controller deals with supporting different events with
	# their own slidesets.
	
	# Only admins should be able to change stuff in here
	before_filter :require_global_admin
	
	# List all events
	def index
		@events = Event.all
	end
	
	# Form for creating a new event
	def new
		@event = Event.new
	end

	# Create a new event
	def create
		Event.transaction do 
			@event = Event.new(event_params)
		
			if @event.save
				flash[:notice] = "Event created."
			else
				flash[:error] = "Error creating event"
				render :action => :new
				return
			end
			redirect_to :action => :index
		end
	end
	
	# Show details for a given event
	def show
		@event = Event.find(params[:id])
	end
	
	# Get edit form for a event
	def edit
		@event = Event.find(params[:id])
	end
	
	# Update a existing event
	def update
		@event = Event.find(params[:id])
		if @event.update_attributes(event_params)
			flash[:notice] = 'Event was successfully updated.'
			redirect_to :action => :index
		else
			render :action => 'edit'
		end
	end
	
	private
	
	# Whitelist parameters for mass-assignment. We also deal with the resolution parameter.
	def event_params
		p = params.required(:event).permit(:name, :current)
		if params[:resolution]
			p[:picture_size] = Event::SupportedResolutions[params[:resolution].to_i]
		end
		return p
	end
	
end
