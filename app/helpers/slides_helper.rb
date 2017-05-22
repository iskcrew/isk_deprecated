# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

module SlidesHelper
  # Extract value for a input for a template slide
  def template_slide_value(slide, field)
    return field.default_value unless slide.respond_to? :slidedata
    return slide.slidedata[field.element_id]
  end

  # Cache key for user-dependant slide info block
  def slide_key(slide)
    "#{slide.cache_key}#{current_user.cache_key}"
  end

  # Render the slide duration as text
  def slide_duration(slide)
    return "Using presentation default" if slide.duration == -1
    return "Infinite" if slide.duration.zero?
    return "#{slide.duration} seconds"
  end

  # <img> tag for the slide preview image
  # FIXME: DRY with other images
  def slide_preview_image_tag(slide)
    html_options = {
      class: "preview #{slide.public ? 'slide-public' : 'slide-hidden'}",
      id: "slide_preview_#{slide.id}"
    }

    if slide.ready
      url = preview_slide_path(slide, t: slide.images_updated_at.to_i)
    else
      url = "wait.gif"
    end

    return image_tag url, html_options
  end

  # <img> tag for the slide thumbnail
  # FIXME: DRY with other images
  def slide_thumb_image_tag(slide)
    html_options = {
      class: "thumb " + (slide.public ? "slide-public" : "slide-hidden"),
      id: "slide_thumb_#{slide.id}"
    }
    if slide.ready
      url = thumb_slide_path(slide, t: slide.images_updated_at.to_i)
    else
      url = "wait.gif"
    end
    return image_tag url, html_options
  end

  # <img> tag for the slide full image
  def slide_full_image_tag(slide)
    image_tag full_slide_path(slide, t: slide.images_updated_at.to_i),
              class: "full_slide", id: "slide_full_" + slide.id.to_s
  end

  # link to slide#show with the preview image
  # FIXME: DRY with other images
  def slide_preview_to_show_tag(slide)
    html_options = {
      title: "Click to show slide details",
      class: "slide-preview-to-show"
    }
    url_options = slide_path(slide)
    return link_to slide_preview_image_tag(slide), url_options, html_options
  end

  # link to slide#show with the thumb image
  # FIXME: DRY with other images
  def slide_thumb_to_show_tag(slide)
    html_options = {
      title: "Click to show slide details",
      class: "slide-preview-to-show"
    }
    url_options = slide_path(slide)
    return link_to slide_thumb_image_tag(slide), url_options, html_options
  end

  # link to slide#full with the preview image
  def slide_preview_to_full_tag(slide)
    html_options = {
      title: "Click to show full size slide image",
      class: "slide-preview-to-full"
    }
    url_options = full_slide_path(slide)
    return link_to slide_preview_image_tag(slide), url_options, html_options
  end

  # Helpers used for generating the simple editor widgets
  def simple_color_select(f, color)
    f.select :color, options_for_select(simple_colors, color), {},
             id: "simple_color", data: { simple_field: true }
  end

  def simple_text_size_select(f, size)
    f.select :text_size, options_for_select(simple_text_sizes, size), {},
             id: "simple_text_size", data: { simple_field: true }
  end

  def simple_text_align_select(f, align)
    f.select :text_align, options_for_select(simple_aligns, align), {},
             id: "simple_text_align", data: { simple_field: true }
  end

  # A button to hide the slide or just inactive toggle, depending on user permissions
  def slide_hide_button_or_status(s)
    return slide_toggle_button("Public", s, :public) if s.can_edit? current_user
    return inactive_toggle("Public", s.public) unless s.can_hide?(current_user) && s.public == true
    return toggle_link_to "Public", s.public, hide_slide_path(s),
                          method: :post,
                          remote: true,
                          data: {
                            confirm: "Are you sure you want to hide this"\
                                     " slide? You cannot publish it later!"
                          }
  end

  # Generic toggle button to toggle some boolean on the slide
  # FIXME OLD STYLE LINK PARAMETERS
  def slide_toggle_button(name, slide, attrib)
    toggle_link_to name, slide.send(attrib),
                   slide_path(slide, slide: { attrib => !slide.send(attrib) }),
                   method: :patch, remote: true
  end

  # Generate the edit link with consistent confirm message
  def slide_edit_link(slide)
    link_to edit_link_text, edit_slide_path(slide),
            class: "btn btn-warning", data: { confirm: (
            slide.public ? "This is a public slide, are you sure you want to edit it?" : nil) }
  end

  # Generate the download svg link for the slide with consistent confirm message
  def slide_svg_link(slide)
    return unless [InkscapeSlide].include? slide.class
    link_text = icon "download", "SVG"
    link_to link_text, svg_data_slide_path(slide),
            class: "btn btn-primary", title: "Download slide in SVG format",
            data: { confirm: (
            slide.public ? "This is a public slide, are you sure you want to edit it?" : nil) }
  end

  # Generate the slide clone button with tooltip
  def slide_clone_button(slide)
    slide_clone_link(slide, "btn btn-primary")
  end

  def slide_clone_link(slide, html_class = nil)
    link_to icon("copy", "Clone"), clone_slide_path(slide),
            method: :post, title: "Create clone of this slide", class: html_class
  end

  # Generate the slide delete button setting the tooltip and confirm message
  def slide_delete_button(slide)
    slide_delete_link(slide, "btn btn-danger", true)
  end

  # Delete link for dropdowns
  def slide_delete_link(slide, html_class = nil, remote = false)
    link_to delete_link_text, slide_path(slide),
            data: { confirm: "Are you sure?" },
            title: "Mark this slide as deleted, you can undo later",
            method: :delete, class: html_class, remote: remote
  end

  # Ungroup slide button
  def slide_ungroup_button(slide)
    slide_ungroup_link(slide, "btn btn-warning")
  end

  # Ungroup link for dropdowns
  def slide_ungroup_link(slide, html_class = nil)
    link_to icon("chain-broken", "Ungroup"),
            slide_path(slide, slide: { master_group_id: current_event.ungrouped_id }),
            method: :put, class: html_class
  end

  # Link to next slide in the same group as this slide
  def slide_next_in_group_link(slide)
    s = slide.master_group.slides.where("position > #{slide.position}").first
    return unless s
    link_to safe_join(["Next slide ", icon("forward")]),
            slide_path(s), class: "btn btn-primary btn-xs"
  end

  # Link to previous slide in the same group as this slide
  def slide_previous_in_group_link(slide)
    s = slide.master_group.slides.where("position < #{slide.position}").reorder(position: :desc).first
    if s
      link_to safe_join([icon("backward"), " Previous slide"]), slide_path(s), class: "btn btn-primary btn-xs"
    end
  end

  # Turn the slide class into human readable slide type
  def slide_class(s)
    return "Template slide" if s.is_a? TemplateSlide
    return "Inkscape slide" if s.is_a? InkscapeSlide
    return "Online simple editor slide" if s.is_a? SimpleSlide
    return "Online SVG-editor slide" if s.is_a? SvgSlide
    return "Video presentation" if s.is_a? VideoSlide
    return "Automatically updating Http-slide" if s.is_a? HttpSlide
    return "Plain bitmap slide" unless s.is_svg?
    return "Unknown"
  end

  # Links for filtering the slide list on slides#index
  def slide_filter_links(filter)
    content_tag "div", class: "btn-group" do
      link_to("All slides", slides_path, class: (filter ? "btn btn-primary" : "btn btn-primary active")) +
        link_to("Thrashed", slides_path(filter: "thrashed"), class: (filter == :thrashed ? "btn btn-primary active" : "btn btn-primary"))
    end
  end

private

  # Colors for the simple editor
  def simple_colors
    double_array current_event.config[:simple][:colors]
  end

  # Text align options for the simple editor
  def simple_aligns
    double_array ["Left", "Left Centered", "Centered", "Right Centered", "Right"]
  end

  # Text size options for the simple editor
  def simple_text_sizes
    double_array current_event.simple_editor_settings[:font_sizes]
  end

  # To generate the selects for simple editor in a sane way we want to turn
  # the arrays containing the options into arrays of arrays with two elements
  # this is needed for the select helpers
  def double_array(v)
    ret = Array.new
    v.each do |a|
      ret << [a, a]
    end
    return ret
  end
end
