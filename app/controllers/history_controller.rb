class HistoryController < ApplicationController
	
	def index
		if params[:display_id].present?
			@display = Display.find(params[:display_id])
			@all_slides = @display.display_counts.joins(:slide).order('count_all desc')
				.group("slides.name", "slides.id").count
			render :index_by_display and return
		else
			@slide = Slide.find(params[:slide_id])
			@displays = @slide.display_counts.joins(:display).order('count_all desc')
				.group("displays.name", "displays.id").count
			render :index_by_slide and return
		end
	end
	
	def show
		@display = Display.find(params[:display_id])
		@slide = Slide.find(params[:id])
		@display_counts = @display.display_counts.where(slide_id: @slide.id).order(updated_at: :asc)
	end
	
	def clear
		display = Display.find(params[:display_id])
		
		# Check for access
		raise ApplicationController::PermissionDenied unless display.admin? current_user
		
		display.display_counts.delete_all
		flash[:notice] = "Cleared slide history for #{display.name}."
		redirect_to display_history_index_path(display)
	end
	
end
