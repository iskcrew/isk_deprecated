# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class SchedulesController < ApplicationController
	#TODO: correct ACL
	
	before_filter :require_global_admin

	def index
		@schedules = Schedule.all
	end
	
	def show
		@schedule = Schedule.find(params[:id])
	end
	
	def new
		@schedule = Schedule.new
	end
	
	def create
		Schedule.transaction do
			@schedule = Schedule.new(params[:schedule])
			if @schedule.save
				flash[:notice] = "Schedule created"
				redirect_to :action => :show, :id => @schedule.id
			else
				flash[:error] = "Error creating schedule"
				render :new and return
			end
		end
	end
	
	def edit
		@schedule = Schedule.find(params[:id])
		@new_event = ScheduleEvent.new
	end
	
	def update
		Schedule.transaction do
			@schedule = Schedule.find(params[:id])
			
			if @schedule.update_attributes(params[:schedule])
				flash[:notice] = 'Schedule updated'
				@schedule.delay.generate_slides
				redirect_to :action => :show, :id => @schedule.id
			else
				flash[:error] = "Error updating schedule"
				render :edit
			end
			
		end
	end
	
	def add_event
		Schedule.transaction do 
			@schedule = Schedule.find(params[:id])
			event = @schedule.schedule_events.new 
			event.update_attributes(params[:schedule_event])
			@schedule.delay.generate_slides
			respond_to do |format|
				format.html {
					redirect_to :action => :show, :id => @schedule.id
				}
				
				format.js {
					@message = 'Event added'
					render :update_form
				}
			end
		end
	end
	
	def destroy_event
		Schedule.transaction do
			event = ScheduleEvent.find(params[:id])
			@schedule = event.schedule
			event.destroy
			
			respond_to do |format|
				format.html {
					redirect_to :action => :show, :id => @schedule.id
				}
				
				format.js {
					@message = "Event deleted"
					render :update_form
				}
			end
			
		end
	end
	
end
