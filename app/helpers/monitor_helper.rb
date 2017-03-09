# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

module MonitorHelper
  def monitor_check_box(obj, name = nil)
    check_box_tag "monitor_#{obj.class.base_class.name.downcase}_#{obj.id}"
  end
end
