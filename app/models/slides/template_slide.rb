class TemplateSlide < InkscapeSlide
	TypeString = 'template'

	belongs_to :template, foreign_key: :foreign_object_id, class_name: 'SlideTemplate'
	
	#TODO: validations, template must exist
	
	include HasSlidedata
	
	# If our slidedata chances mark the slide as not ready when saving it.
	before_save do
		if @_slidedata.present?
			generate_svg
		end
		true
	end
	
	def generate_images
		generate_svg
		super
	end
	
	private
	
	def generate_svg
		self.svg_data = self.template.generate_svg(self.slidedata)
		write_svg_data
	end
		
	def default_slidedata
		default = ActiveSupport::HashWithIndifferentAccess.new
		self.template.fields.editable.each do |f|
			default[f.element_id.to_sym] = f.default_value
		end
		return default
	end

end