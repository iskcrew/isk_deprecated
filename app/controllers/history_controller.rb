class HistoryController < ApplicationController
	
	def index
		@display = Display.find(params[:display_id])
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
