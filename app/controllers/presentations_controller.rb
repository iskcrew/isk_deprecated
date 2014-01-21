# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class PresentationsController < ApplicationController
	before_filter :require_create, :only => [:new, :create]
  
	cache_sweeper :presentation_sweeper
	
	# List all presentations
	#TODO: bind presentations to events and only list current ones
	def index
		@presentations = Presentation.all
	end
   
	# Show details of a presentation
	# Supports html and json output
	def show
		@presentation = Presentation.find(params[:id])
    
		respond_to do |format|
			format.html
			format.json {render :json =>JSON.pretty_generate(@presentation.to_hash)}
      
		end
	end
  
	#Change the order of groups in a presentation
	#Triggered from jquery.sortable widged via ajax
	def sort
		p = Presentation.find(params[:id])
		require_edit p
    
		if params[:group].count == p.groups.count
			Presentation.transaction do
				p.groups.each do |g|
					g.position = params[:group].index(g.id.to_s) + 1
					g.save
				end
			end
			p.reload
			render :partial => 'group_items', :locals => {:presentation => p}
		else
			render :text => "Invalid group count, try refreshing", :status => 400
		end
    
	end
  
	#Add all slides in this presentation into override queue for a display
	def add_to_override
		presentation = Presentation.find(params[:id])
		display = Display.find(params[:override][:display_id])
		duration = params[:override][:duration].to_i
    
		if display.can_override?(current_user)
			presentation.slides.each do |s|
				display.add_to_override(s, duration)
			end
			flash[:notice] = "Added presentation " + presentation.name + " to override on display " + display.name
		else
			flash[:error] = "You can't add slides to the override queue on display " + display.name
		end
		redirect_to :action => :show, :id => presentation.id
    
	end
  
	#Add a single group to a presentation
	#TODO: move the logic to model
	def add_group
			@presentation = Presentation.find(params[:id])
			require_edit @presentation
      
			g = @presentation.groups.new
			g.master_group_id = params[:group][:id]
			@presentation.groups << g
			g.save!
			flash[:notice] = "Added group " + g.name + " to presentation"
			redirect_to :back
	end
  
	#Remove a single group from this presentation
	def remove_group
		g = Group.find(params[:id])
		p = g.presentation
		require_edit p
    
		g.destroy
		flash[:notice] = "Removed group " + g.name + " from presentation"
		redirect_to :back
	end
    
	#Generate a preview of the presentation, showing all the slides in order
	def preview
		@presentation = Presentation.find(params[:id])
	end
  
	#Render form for creating a new presentation  
	def new
		@presentation = Presentation.new
	end
  
	#Create a new presentation
	#If the current user isn't admin add him to the ACL list for this presentation
	def create
		@presentation = Presentation.new(params[:presentation])
		if @presentation.save
			@presentation.authorized_users << current_user unless Presentation.admin?(current_user)
			flash[:notice] = 'Presentation was successfully created.'
			redirect_to :action => :show, :id => @presentation.id
		else
			render :action => :new
		end  
	end
    
	#Render the edit form for a presentation
	def edit
		@presentation = Presentation.find(params[:id])
		require_edit @presentation
    
		#Seeing what groups aren't already in the presentation is useful sometimes
		@orphan_groups = Event.current.master_groups.defined_groups.joins('LEFT OUTER JOIN groups on master_groups.id = groups.master_group_id').where('groups.presentation_id  IS NULL OR (groups.presentation_id <> ? )', params[:id]).uniq.all
	end  
  
	#Update a presentation
	#TODO: rewrite the js so that #sort method can be killed off and use this instead  
	def update
		@presentation =Presentation.find(params[:id])
		require_edit @presentation
    
		if @presentation.update_attributes(params[:presentation])
			flash[:notice] = 'Presentation was successfully updated.'
			redirect_to :action => 'show', :id => @presentation.id
		else
			render :action => 'edit'
		end
	end
  
	# Remove a user from the ACL for this presentation
	def deny
		presentation = Presentation.find(params[:id])
		user = User.find(params[:user_id])
		presentation.authorized_users.delete(user)
		redirect_to :back
	end
  
	# Add a user to the ACL for this presentation
	def grant
		presentation = Presentation.find(params[:id])
		user = User.find(params[:grant][:user_id])
		presentation.authorized_users << user
		redirect_to :back    
	end
  
  
	private
  
	#Filter for actions requiring presentation_admin role
	def require_admin
		raise ApplicationController::PermissionDenied unless Presentation.admin? current_user
	end
  
	#Filter for actions requiring presentation_create role
	def require_create
		raise ApplicationController::PermissionDenied unless Presentation.can_create? current_user
	end
    
end
