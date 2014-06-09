class TemplateSlide < SvgSlide
	TypeString = 'template'

	belongs_to :template, foreign_key: :foreign_object_id
	
	include HasSlidedata
	
	private
	
	def sanitize_slidedata(d)
		return d
	end
	
	def default_slidedata
		
	end

end