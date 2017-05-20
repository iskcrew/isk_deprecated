# frozen_string_literal: true
# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

module GroupsHelper
  # Cache key for group reated stuff
  def group_cache_key(group)
    group.cache_key + current_user.cache_key
  end

  # Construct a link to a group with basic group infor
  def group_link_tag(g)
    html = String.new
    html << "Group: "
    html << link_to(g.name, group_path(g), name: "group_#{g.id}")
    html << " Slides: #{g.slides.published.count}/#{g.slides.count}"
    return html.html_safe
  end

  def group_download_slides_link(group)
    link_text = icon "download", "Slides (zip)"
    link_to link_text, download_slides_group_path(group), class: "btn btn-primary"
  end

  def group_edit_link(group)
    link_to edit_link_text, edit_group_path(group),
            class: "btn btn-primary",
            title: "Edit slide order and group metadata."
  end
end
