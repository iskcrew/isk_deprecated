# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

module TemplatesHelper
  def current_templates
    @_templates ||= SlideTemplate.current.all
  end

  def template_destroy_link(template)
    link_to "Delete", template_path(template), method: :delete, class: "btn btn-danger"
  end
end
