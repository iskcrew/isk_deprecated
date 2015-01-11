# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class GroupsController < ApplicationController
	before_action :require_create, :only => [:new, :create]
	before_action :require_admin, :only => [:publish_all, :hide_all, :grant, :deny]
	
	# Get list of all groups in the current event
	def index
		@groups = MasterGroup.current.defined_groups.reorder("LOWER(name)")
	end
	
	# Show detailed information about a group
	def show
		@group = MasterGroup.find(params[:id])
	end
	
	# Edit a group, we need to check edit priviledges and dissallow editing of internal groups
	def edit
		@group = MasterGroup.find(params[:id])
		
		if @group.internal
			# Do not allow editing of internal groups
			flash[:error] = "Can't edit internal groups"
			redirect_to group_path(@group) and return
		end
		require_edit @group
			
	end
	
	def update
		@group =MasterGroup.find(params[:id])
		
		if @group.internal
			# Do not allow editing of internal groups
			flash[:error] = "Can't edit internal groups"
			redirect_to group_path(@group) and return
		end
		
		require_edit @group
		
		# Handle prizegroup data
		if @group.is_a? PrizeGroup
			@group.data = params[:master_group][:data]
		end
		
		if @group.update_attributes(master_group_params)
			flash[:notice] = 'Group was successfully updated.'
			redirect_to :action => 'show', :id => @group.id
		else
			render :action => 'edit'
		end
		
	end
	
	# Set all slides in the groups to public
	def publish_all
		@group = MasterGroup.find(params[:id])
		@group.publish_slides
		redirect_to :action => :show, :id => @group.id
	end
	
	# Hide all slides in the group
	def hide_all
		@group = MasterGroup.find(params[:id])
		@group.hide_slides
		redirect_to :action => :show, :id => @group.id
	end
	
	# Change the order of slides in the group, used with jquerry sortable widget.
	def sort
		@group = MasterGroup.find(params[:id])
		require_edit @group
		
		if s = @group.slides.find(params[:element_id])
			s.position_position = params[:element_position]
			s.save!
			@group.reload
			respond_to do |format|
				format.js {render :sortable_items}
			end
		else
			render :text => "Invalid request data", :status => 400
		end		
	end

	# Delete a group, all contained slides will become ungrouped
	def destroy
		@group = MasterGroup.find(params[:id])
		require_edit @group
		@group.destroy
		
		redirect_to :action => :index
	end
	
	# Add multiple slides to group, render the selection form for all ungrouped slides
	def add_slides
		@group = MasterGroup.find(params[:id])
		require_edit @group
		
		@slides = current_event.ungrouped.slides.current.to_a
	end
	
	# Add multiple slides to group
	def adopt_slides
		@group = MasterGroup.find(params[:id])
		require_edit @group
		added = Array.new
		params[:add_slides].each do |id|
			s = current_event.ungrouped.slides.find(id)
			added << s.name
			s.master_group_id = @group.id
			s.save!
		end
		
		if added.present?
			flash[:notice] = "Added #{added.size} #{'slide'.pluralize(added.size)} to group #{@group.name}."
		end
		
		redirect_to :action => :show, :id => @group.id
	end
	
	def new
		@group = MasterGroup.new
	end
	
	# FIXME: move creation logic to models
	def create
		if params[:prize]
			# Create new prize ceremony group
			@group = PrizeGroup.new(master_group_params)
			@group.event = current_event
			@group.data = params[:master_group][:data]
		else
			# Create normal group
			@group = MasterGroup.new(master_group_params)
			@group.event = current_event
		end
		
		if @group.save
			flash[:notice] = "Group created."
			@group.authorized_users << current_user unless MasterGroup.admin? current_user
			redirect_to :action => :show, :id => @group.id
		else
			flash[:error] = "Error saving group"
			render :new and return
		end 
			
	end
	
	# Download the slides as a zip archive
	def download_slides
		group = MasterGroup.find(params[:id])
		send_data group.zip_slides, filename: "group_#{group.id}_#{group.name}.zip"
	end
	
	def deny
		group = MasterGroup.find(params[:id])
		user = User.find(params[:user_id])
		group.authorized_users.delete(user)
		redirect_to :back
	end
	
	def grant
		group = MasterGroup.find(params[:id])
		user = User.find(params[:grant][:user_id])
		group.authorized_users << user
		redirect_to :back		 
	end
	
	# Add all slides on this group to override on a display
	def add_to_override
		group = MasterGroup.find(params[:id])
		display = Display.find(params[:override][:display_id])
		duration = params[:override][:duration].to_i
		
		if display.can_override?(current_user)
			group.slides.each do |s|
				display.add_to_override(s, duration)
			end
			flash[:notice] = "Added group " + group.name + " to override on display " + display.name
		else
			raise ApplicationController::PermissionDenied
		end
		redirect_to :action => :show, :id => group.id
		
	end
	
	private
	
	# Whitelist the parameters for creating and editing groups
	def master_group_params
		params.required(:master_group).permit(:name, :effect_id)
	end
	
	def require_create
		raise ApplicationController::PermissionDenied unless MasterGroup.can_create?(current_user)
	end
		
	def require_admin
		raise ApplicationController::PermissionDenied unless MasterGroup.admin?(current_user)
	end
	
end
