class HistoryController < ApplicationController
	
	def index
		@display = Display.find(params[:display_id])
	end
	
	def show
		@display = Display.find(params[:display_id])
		@slide = Slide.find(params[:id])
		@display_counts = @display.display_counts.where(slide_id: @slide.id).order(updated_at: :asc)
	end
	
end
