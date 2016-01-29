# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

class EventsController < ApplicationController
	# This controller deals with supporting different events with
	# their own slidesets.
	
	# Only admins should be able to change stuff in here
	before_action :require_global_admin
	
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
				render action: :new
				return
			end
			redirect_to events_path
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
			redirect_to event_path(@event)
		else
			flash.now[:error] = 'Error updating event.'
			render action: :edit
		end
	end
	
	# Destroy a event
	# FIXME: The deletion is currently not routed.
	# we need to figure out what to do with all the slides etc associated to the deleted event.
	def destroy
		event = Event.find(params[:id])
		if event.destroy
			flash[:notice] = "Deleted event #{event.name}"
			redirect_to events_path, status: :see_other
		else
			flash[:error] = "Error deleting event #{event.name}!"
			redirect_to events_path
		end
	end
	
	# (re)generate all slide images for this event
	def generate_images
		@event = Event.find(params[:id])
		@event.generate_images_later
		flash[:notice] = "Regenerating slide images, this will take a while.."
		redirect_to event_path(@event)
	end
	
	private
	
	# Whitelist parameters for mass-assignment. We also deal with the resolution parameter.
	def event_params
		params.required(:event).permit(
			:name,
			:current,
			:resolution,
			:simple_heading_font_size,
			:simple_heading_x,
			:simple_heading_y,
			:simple_body_margin_left,
			:simple_body_margin_right,
			:simple_body_y,
			:schedules_per_slide,
			:schedules_line_length,
			:schedules_tolerance,
			:schedules_subheader_fill,
			:schedules_time_indent,
			:schedules_event_indent,
			:schedules_font_size,
			:schedules_line_spacing
		)
	end
	
end
