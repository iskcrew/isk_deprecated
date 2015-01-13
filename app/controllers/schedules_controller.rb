# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class SchedulesController < ApplicationController
	# TODO: correct ACL
	# We require admin priviledges for all actions for now...
	before_action :require_global_admin
	
	# List all schedules
	# TODO: only for current event
	def index
		@schedules = Schedule.all
	end

	# Show details on given schedule
	def show
		@schedule = Schedule.find(params[:id])
	end

	# Render a form to create a new schedule
	def new
		@schedule = Schedule.new
	end

	# Create a new schedule based on the POST params
	def create
		Schedule.transaction do
			@schedule = Schedule.new(schedule_params)
			if @schedule.save
				flash[:notice] = "Schedule created"
				redirect_to :action => :show, :id => @schedule.id
			else
				flash[:error] = "Error creating schedule"
				render :new and return
			end
		end
	end

	# Render edit form for a schedule
	def edit
		@schedule = Schedule.find(params[:id])
		@new_event = ScheduleEvent.new
	end

	# Update a schedule based on the post parameters
	def update
		@schedule = Schedule.find(params[:id])

		if @schedule.update_attributes(schedule_params)
			flash[:notice] = 'Schedule updated'
			@schedule.delay.generate_slides
			respond_to do |format|
				format.html {
					redirect_to schedule_path(@schedule)
				}

				format.js {
					@message = 'Event added'
					render :update_form
				}
			end
		else
			flash[:error] = "Error updating schedule"
			render :edit
		end
	end

	private

	# Whitelist POST parameters for create and update
	def schedule_params
		params.required(:schedule).permit(:name, :max_slides, :min_events_on_next_day, :up_next,
			{schedule_events_attributes: [:id, :name, :major, :at, :_destroy ]}
			)
	end
end
