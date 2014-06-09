class TemplateSlide < SvgSlide
	TypeString = 'template'

	belongs_to :template, foreign_key: :foreign_object_id, class: 'SlideTemplate'
	
	#TODO: validations, template must exist
	
	include HasSlidedata
	
	private
		
	def default_slidedata
		default = {}
		self.template.fields.editable.each do |f|
			default[f.element_id] = f.default_value
		end
		return default
	end

end