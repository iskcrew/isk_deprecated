# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

class PresentationsController < ApplicationController
	# ACLs
	before_action :require_create, only: [:new, :create]
	
	# List all presentations
	# TODO: bind presentations to events and only list current ones
	def index
		@presentations = current_event.presentations.order(:name)
	end
	
	# Show details of a presentation
	# Supports html and json output
	def show
		@presentation = Presentation.find(params[:id])
		
		respond_to do |format|
			format.html
			format.json {render json: JSON.pretty_generate(@presentation.to_hash)}
		end
	end
	
	# Render form for creating a new presentation
	def new
		@presentation = Presentation.new
	end
	
	# Create a new presentation
	# If the current user isn't admin add him to the ACL list for this presentation
	def create
		@presentation = Presentation.new(presentation_params)
		if @presentation.save
			@presentation.authorized_users << current_user unless Presentation.admin?(current_user)
			flash[:notice] = 'Presentation was successfully created.'
			redirect_to presentation_path(@presentation)
		else
			render action: :new
		end
	end
		
	# Render the edit form for a presentation
	def edit
		@presentation = Presentation.find(params[:id])
		require_edit @presentation
		
		#Seeing what groups aren't already in the presentation is useful sometimes
		@orphan_groups = current_event.master_groups.defined_groups.joins('LEFT OUTER JOIN groups on master_groups.id = groups.master_group_id').where('groups.presentation_id	IS NULL OR (groups.presentation_id <> ? )', params[:id]).uniq
	end
	
	# Update a presentation
	# TODO: rewrite the js so that #sort method can be killed off and use this instead
	def update
		@presentation =Presentation.find(params[:id])
		require_edit @presentation
		
		if @presentation.update_attributes(presentation_params)
			flash[:notice] = 'Presentation was successfully updated.'
			redirect_to presentation_path(@presentation)
		else
			render action: :edit
		end
	end
	
	# Delete a presentation
	def destroy
		@presentation = Presentation.find(params[:id])
		require_edit @presentation
		@presentation.destroy
		flash[:notice] = "Deleted presentation '#{@presentation.name}'"
		redirect_to presentations_path, status: :see_other
	end
	
	# Change the order of groups in a presentation
	# Triggered from jquery.sortable widged via ajax
	def sort
		@presentation = Presentation.includes(groups: :master_group).find(params[:id])
		require_edit @presentation
		
		if g = @presentation.groups.find(params[:element_id])
			g.position_position = params[:element_position]
			g.save!
			@presentation.reload
			respond_to do |format|
				format.js {render :sortable_items}
			end
		else
			render text: "Invalid group count, try refreshing", status: 400
		end
	end
	
	# Add all slides in this presentation into override queue for a display
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
		redirect_to presentation_path(presentation)
	end
	
	# Add a single group to a presentation
	# TODO: move the logic to model
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
	
	# Remove a single group from this presentation
	def remove_group
		g = Group.find(params[:id])
		p = g.presentation
		require_edit p
		
		g.destroy
		flash[:notice] = "Removed group " + g.name + " from presentation"
		redirect_to :back
	end
	
	# Generate a preview of the presentation, showing all the slides in order
	def preview
		@presentation = Presentation.find(params[:id])
	end
			
	private
	
	def presentation_params
		params.required(:presentation).permit(:name, :effect_id, :delay)
	end
	
	# Filter for actions requiring presentation_admin role
	def require_admin
		raise ApplicationController::PermissionDenied unless Presentation.admin? current_user
	end
	
	# Filter for actions requiring presentation_create role
	def require_create
		raise ApplicationController::PermissionDenied unless Presentation.can_create? current_user
	end
end
