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
			redirect_to edit_template_path(@template)
		else
			flash[:error] = "Error saving template"
			render :new
		end
	end
	
	#Change the order of slides in the group, used with jquerry sortable widget.
	def sort
		@template = SlideTemplate.find(params[:id])
		
		if f = @template.fields.find(params[:element_id])
			f.field_order_position = params[:element_position]
			f.save!
			@template.reload
			respond_to do |format|
				format.js {render :sortable_items}
			end
		else
			render :text => "Invalid request data", :status => 400
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
		params.required(:slide_template).permit(
			:name, 
			:upload, 
			fields_attributes: [:id, :editable, :multiline, :color, :default_value]
		)
	end

	def template_params
		params.required(:slide_template).permit(:name, :upload)
	end
	
end
