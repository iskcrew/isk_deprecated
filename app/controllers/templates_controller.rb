class TemplatesController < ApplicationController
	# TODO: proper filters
	before_filter :require_global_admin
	
	def index
		@templates = SlideTemplate.all
	end
	
	def show
		@template = SlideTemplate.find(params[:id])
	end
	
	def new
		@template = SlideTemplate.new
	end
	
	def create
		@template = SlideTemplate.new(template_params)
		@template.event = current_event
		
		if @template.save
			flash[:notice] = 'Template created'
			redirect_to template_path(@template)
		else
			flash[:error] = "Error saving template"
			render :new
		end
	end
	
	def edit
		@template = SlideTemplate.find(params[:id])
	end
	
	def update
		@template = SlideTemplate.find(params[:id])

		if @template.update_attributes(update_params)
			flash[:notice] = 'Template was successfully updated.'
			redirect_to template_path(@template)
		else
			render :action => 'edit'
		end
		
	end
	
	def destroy
		
	end
	
	private
	
	def update_params
		s = {}
		@template.settings.each_key do |k|
			s[k] = [:edit, :multiline, :color, :default]
		end
		params.required(:slide_template).permit(:name, :upload, settings: s)
	end

	def template_params
		params.required(:slide_template).permit(:name, :upload)
	end
	
end
