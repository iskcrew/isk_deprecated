# ISK - A web controllable slideshow system
#
# This controller handles the managing of remote isk displays.
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class DisplaysController < ApplicationController
	# ACL filters
	before_action :require_create, only: [:new, :create]
	
	# List all displays
	# We support html or json for the whole list and
	# js for updating the late display warnings on pages.
	def index
		@displays = Display.order(:name)
		
		respond_to do |format|
			format.js
			format.html
			format.json {
				render json: @displays.collect { |d|
					{
						id: d.id,
						name: d.name,
						status: d.status,
						late: d.late?}
					}
			}
		end
	end
	
	# Get the details on a given display
	# We support html, json for the data serilazation and
	# js for updating the div#display_<id> blocks
	def show
		@display = Display.includes(:presentation, override_queues: :slide).find(params[:id])
		
		respond_to do |format|
			format.html 
			format.json {
				render json: JSON.pretty_generate(@display.to_hash)
			}
			format.js
		end
	end
	
	# Delete a display and associated data
	def destroy
		# Only admins can delete displays
		require_admin
		
		display = Display.find(params[:id])
		display.destroy
		flash[:notice] = "Deleted display id: #{display.id} - #{display.name}"
		redirect_to displays_path, status: :see_other
	end
	
	# FIXME: allow creation of displays from the web gui
	def new
		
	end
	
	def create
		
	end
	
	# Render the edit form for a given display
	def edit
		@display = Display.find(params[:id])
		require_edit @display
	end
	
	# Update a given display
	# We support html and js, that updates the div#display_<id> block
	def update
		@display = Display.find(params[:id])
		require_edit @display

		if @display.update_attributes(display_params)
			respond_to do |format|
				format.html {
					flash[:notice] = 'Display was successfully updated.'
					redirect_to display_path(@display), status: :see_other
				}
				format.js {render :show}
			end
		else
			flash.now[:error] = "Error updating display."
			render action: :edit and return
		end		 
	end	 
	
	# FIXME: create a nested override controller
	def update_override
		oq = OverrideQueue.find(params[:id])
		require_edit oq.display
		
		oq.duration = params[:override_queue][:duration]
		oq.save!
		flash[:notice] = "Duration was changed"
		redirect_to :back
	end
	
	def remove_override
		oq = OverrideQueue.find(params[:id]).destroy
		require_override oq.display
		
		flash[:notice] = 'Removed slide from override queue'
		redirect_to :back
	end
	
	#Remote control for iskdpy via javascript and websockets
	def dpy_control
		@display = Display.find(params[:id])
	end
					
	#FIXME: this logic needs to go to the model
	def sort_queue
		@display = Display.find(params[:id])
		require_edit @display
		
		if oq = @display.queue.find(params[:element_id])
			oq.position_position = params[:element_position]
			oq.save!
			@display.reload
			respond_to do |format|
				format.js {render :sortable_items}
			end
		else
			render text: "Invalid request, try refreshing", status: :bad_request
		end				
	end
	
	# FIXME: the ACL stuff needs to go to nested controller
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
	
	# Whitelist the parameters for updating displays
	def display_params
		params.required(:display).permit(:name, :presentation_id, :manual, :monitor, :do_overrides)
	end
	
	# Require display admin priviledges or raise PermissionDenied
	def require_admin
		raise ApplicationController::PermissionDenied unless Display.admin? current_user
	end
	
	# Require display create permission or raise PermissionDenied
	def require_create
		raise ApplicationController::PermissionDenied unless Display.can_create? current_user
	end
	
	# Require permission to add slides to the override queue on a display
	def require_override(d)
		raise ApplicationController::PermissionDenied unless d.can_override? current_user
	end
end
