# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

module DisplaysHelper
  # Links to the details for all late displays
  def late_display_warning(d)
    link_text = "#{d.name} (#{d.ip}) is more than #{Display::TIMEOUT} minutes late!"
    link_to link_text, display_path(d), class: "alert-link"
  end

  # Link to displays#destroy if user has sufficient access
  def display_destroy_button(d)
    return unless d.admin?(current_user)
    link_to icon("times-circle", "Delete"), display_path(d),
            data: {
                    confirm: "Are you sure you want to delete the display"\
                             " \"#{d.name}\", this cannot be undone?"
                  },
            title: "Delete this display premanently",
            method: :delete, class: "button warning"
  end

  # Set the panel class based on display status
  def display_class(display)
    case display.status
    when "running"
      if display.late?
        panel = "panel-warning"
      else
        panel = "panel-success"
      end
    when "disconnected"
      panel = "panel-default"
    else
      panel = "panel-danger"
    end
    return "#{panel} display-live" if display.live?
    return panel
  end

  # Render the display ping element
  def display_ping(d)
    if d.late?
      html_class = "late"
    else
      html_class = "on_time"
    end

    if d.last_contact_at
      ping_seconds = (Time.now - d.last_contact_at).to_i
      ping_seconds = ">60" if ping_seconds > 60
    else
      ping_seconds = "UNKNOWN"
    end

    return content_tag(:span, "Ping: #{ping_seconds} s.", class: html_class)
  end

  # Render the img element for the current slide image
  def display_current_slide(d)
    if (d.status != "error") && d.current_slide.present?
      image = slide_preview_image_tag d.current_slide
    else
      image = image_tag("display_error.png", class: "preview")
    end
    html_options = {
      title: "Click to show display details",
      class: "slide_preview"
    }

    return link_to image, display_path(d), html_options
  end

  # Render the last_contact_at timestamp and the diff to current time
  def display_last_contact(d)
    return "UNKNOWN" unless d.last_contact_at
    delta = Time.diff(Time.now, d.last_contact_at, "%h:%m:%s")[:diff]
    return "#{l d.last_contact_at, format: :short} (#{delta} ago)"
  end
end
