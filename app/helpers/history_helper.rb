# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

module HistoryHelper
  # First slide shown on the display
  def display_first_slide(d)
    first_shown = d.display_counts.order(updated_at: :asc).first
    l first_shown.updated_at, format: :short
  end

  def slide_first_display(s)
    first_shown = s.display_counts.order(updated_at: :asc).first
    timestamp = l first_shown.updated_at, format: :short
    return "#{timestamp} on display #{link_to first_shown.display.name, display_path(first_shown.display)}".html_safe
  end
end
