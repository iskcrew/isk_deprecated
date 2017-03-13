# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

module PermissionsHelper
  # Get the path for a given object type for the nested permission controller
  def permission_path(obj, options = {})
    if obj.is_a? Slide
      slide_permission_path(obj, options)
    elsif obj.is_a? MasterGroup
      group_permission_path(obj, options)
    elsif obj.is_a? Display
      display_permission_path(obj, options)
    elsif obj.is_a? Presentation
      presentation_permission_path(obj, options)
    else
      raise ArgumentError, "Unexpected class: #{obj.class}"
    end
  end
end
