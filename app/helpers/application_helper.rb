# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

module ApplicationHelper
  # Generate the top navigation tabs and set a special style
  # for the tab of the current controller
  def navigation_links
    controllers = ["Slides", "Groups", "Presentations", "Displays", "Schedules", "Tickets"]
    ret = String.new
    # Build navigation tabs for basic controllers
    tabs = controllers
    tabs.each do |c|
      html_options = {
                       class: "",
                       id: "#{c.downcase}_tab"
                     }
      if controller.class.name.include?(c)
        html_options[:class] =	"active"
      end
      ret << content_tag("li", link_to(c, controller: c.downcase), html_options)
    end
    return ret.html_safe
  end

  # Sets the 'active' class if current action matches the provided one
  def active_action?(action)
    controller.action_name == action ? "active" : nil
  end

  # Inactive toggle button with "led"
  def inactive_toggle(name, status)
    if status
      html = "<a class='button inactive led green'>"
    else
      html = "<a class='button inactive led off'>"
    end
    html << name << "</a>"
    return html.html_safe
  end

  # Active toggle button with a "led"
  def toggle_link_to(name, selected, options = {}, html_options = {})
    if selected
      html_options[:class] = "btn btn-primary led green"
      html_options[:title] = "Toggle this off"
    else
      html_options[:class] = "btn btn-primary led off"
      html_options[:title] = "Toggle this on"
    end
    return link_to name, options, html_options
  end

  # Render the authorized users partial with given object
  def authorized_users(obj)
    render partial: "shared/authorized_users", locals: { obj: obj }
  end

  # Render the tickets partial with the given object
  def tickets_partial(obj)
    render partial: "shared/tickets", locals: { obj: obj }
  end

  # Icon for help boxes
  def help_icon
    icon "exclamation-circle", "", class: "fa-2x fa-pull-left"
  end

  # Text for links to details on items
  def details_link_text
    icon "info-circle", "Details"
  end

  # Text for links to edit pages on items
  def edit_link_text
    icon "edit", "Edit"
  end

  # Text for delete links
  def delete_link_text
    icon "times-circle", "Delete"
  end

  # Memoize the current user
  def current_user
    return @_current_user ||= User.first if Rails.env.profile?
    @_current_user ||= session[:user_id] &&
    User.includes(:permissions).find_by_id(session[:user_id])
  end

  # Memioze the current event
  def current_event
    @_current_event ||= Event.current
  end
end
