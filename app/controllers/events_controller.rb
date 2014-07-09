# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class EventsController < ApplicationController
	# This controller deals with supporting different events with
	# their own slidesets.
	
	# Only admins should be able to change stuff in here
	before_filter :require_global_admin
  
  def index
    @events = Event.all
  end
  
  def new
    @event = Event.new
  end

  def show
    @event = Event.find(params[:id])
  end
  
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

  
  def edit
    @event = Event.find(params[:id])
  end
  
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
	
	def event_params
		p = params.required(:event).permit(:name, :current)
		if params[:resolution]
			p[:picture_size] = Event::SupportedResolutions[params[:resolution].to_i]
		end
		return p
	end
  
end
