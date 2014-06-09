class TemplatesController < ApplicationController
	# TODO: proper filters
	before_filter :require_global_admin
	
	def index
		@templates = Template.all
	end
	
	def show
		@template = Template.find(params[:id])
	end
	
	def new
		@template = Template.new
	end
	
	def create
		@template = Template.new(template_params)
		@template.event = current_event
		
		if @template.save
			flash[:notice] = 'Template created'
			redirect_to template_path(@template)
		else
			flash[:error] = "Error saving template"
			render :new
		end
	end
	
	#Change the order of slides in the group, used with jquerry sortable widget.
	def sort
		@template = Template.find(params[:id])
		
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
		@template = Template.find(params[:id])
	end
	
	def update
		@template = Template.find(params[:id])

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
		params.required(:template).permit(
			:name, 
			:upload, 
			fields_attributes: [:id, :editable, :multiline, :color, :default_value]
		)
	end

	def template_params
		params.required(:template).permit(:name, :upload)
	end
	
end
