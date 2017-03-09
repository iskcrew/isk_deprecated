# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

module PresentationsHelper
  # Convert the slide duration from seconds into human readable format
  # FIXME: namespace this properly
  def duration_to_text(dur)
    (Time.mktime(0) + dur).strftime("%H:%M:%S")
  end

  # Link to displays#destroy if user has sufficient access
  def presentation_destroy_button(p)
    if p.can_edit?(current_user)
      link_to delete_link_text, presentation_path(p),
      data: { confirm: "Are you sure you want to delete the presentation \"#{p.name}\", this cannot be undone?" },
      title: "Delete this presentation premanently",
      method: :delete, class: "btn btn-danger"
    end
  end

  # Button to edit a presentation
  def presentation_edit_button(p)
    if p.can_edit? current_user
      return link_to edit_link_text, edit_presentation_path(p), class: "btn btn-primary"
    end
  end
end
