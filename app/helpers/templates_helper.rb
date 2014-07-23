module TemplatesHelper
	def current_templates
		@_templates ||= SlideTemplate.current.all
	end
	
	def template_destroy_link(template)
		link_to 'Delete', template_path(template), method: :delete, class: 'button warning'
	end
	
end
