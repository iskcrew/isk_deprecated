# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class EventsController < ApplicationController
  
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
      @event = Event.new(params[:event])
    
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
    if @event.update_attributes(params[:event])
      flash[:notice] = 'Event was successfully updated.'
      redirect_to :action => :index
    else
      render :action => 'edit'
    end
    
  end
  
  
end
