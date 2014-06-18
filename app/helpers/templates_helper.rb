module TemplatesHelper
	def current_templates
		@_templates ||= SlideTemplate.all
	end
	
end
