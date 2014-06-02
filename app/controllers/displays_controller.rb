# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class DisplaysController < ApplicationController
  before_filter :require_create, :only => [:new, :create]
  
  
  skip_before_filter :require_login, :only => [:show]
    
  def index
    @displays = Display.order(:name)
    
    respond_to do |format|
      format.js
      format.html
    end
    
  end
    
  def show
    @display = Display.includes(:presentation, :override_queues => :slide).find(params[:id])
    
    respond_to do |format|
      format.html 
      format.json {
        render(:json =>JSON.pretty_generate(@display.to_hash))
      }
      format.js
    end
  end
  
  def slide_stats
    @display = Display.find(params[:id])
    
  end
  
  def new
    
  end
  
  def create
    
  end
  
  def edit
    @display = Display.find(params[:id])
    require_edit @display
  end
  
  def update_override
    oq = OverrideQueue.find(params[:id])
    require_edit oq.display
    
    oq.duration = params[:override_queue][:duration]
    oq.save!
    flash[:notice] = "Duration was changed"
    redirect_to :back
  end
  
  def update
    @display = Display.find(params[:id])
    require_edit @display

    if @display.update_attributes(display_params)
      flash[:notice] = 'Display was successfully updated.'
    else
      flash[:error] = "Error updating display."
      render :action => 'edit' and return
    end
    
    respond_to do |format|
      format.html {redirect_to :action => :show, :id => @display.id}
      format.js {render :show}
    end
    
  end  

  #Remote control for iskdpy via javascript and websockets
  def dpy_control
    @display = Display.find(params[:id])
  end
    
  def presentation
    @display = Display.find(params[:id])
    redirect_to :controller => :presentations, :action => :show, :id => @display.presentation.id
  end
  
	
	# FIXME: is this even needed currently?
  def add_slide
    @display = Display.find(params[:id])
    require_edit @display


    @slides = Slide.current
  end
  
	# FIXME: This logic needs to go to the model
  def queue_slide
    display = Display.find(params[:id])
    require_override display

    slide = Slide.current.find(params[:slide_id])

    Display.transaction do 
      oq = display.override_queues.new
      oq.slide = slide
      oq.duration = params[:duration] || 60
      oq.save!
    end
		
		unless display.do_overrides
			flash[:warning] = "WARNING: This display isn't currently showing overrides, displaying this slide will be delayed"
		end
    
		flash[:notice] = 'Added slide ' << slide.name << ' to the override queue'
    redirect_to :action => :show, :id => display.id
    
  end
  
	
	#FIXME: this logic needs to go to the model
  def sort_queue
    Display.transaction do
      d = Display.find(params[:id])
      require_override d
      
      
      if params[:override_queue].count == d.override_queues.count
        d.override_queues.each do |oq|
          oq.position = params['override_queue'].index(oq.id.to_s) + 1
          oq.save
        end
        d.reload
				@display = d
				respond_to do |format|
					format.js {render :sortable_items}
				end
      else
        render :text => "Invalid slide count, try refreshing", :status => 400
      end
    end
    
  end
  
  def remove_override
    oq = OverrideQueue.find(params[:id]).destroy
    require_override oq.display
    
    flash[:notice] = 'Removed slide from override queue'
    redirect_to :back
  end
  
  def deny
    display = Display.find(params[:id])
    user = User.find(params[:user_id])
    display.authorized_users.delete(user)
    redirect_to :back
  end
  
  def grant
    display = Display.find(params[:id])
    user = User.find(params[:grant][:user_id])
    display.authorized_users << user
    redirect_to :back    
  end
  
  
  private
	
	def display_params
		params.required(:display).permit(:name, :presentation_id, :manual, :monitor)
	end
  
  def require_admin
    raise ApplicationController::PermissionDenied unless Display.admin? current_user
  end
  
  def require_create
    raise ApplicationController::PermissionDenied unless Display.can_create? current_user
  end
  
  def require_override(d)
    raise ApplicationController::PermissionDenied unless d.can_override? current_user
  end
 


end
