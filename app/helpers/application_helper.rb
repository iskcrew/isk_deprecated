# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


module ApplicationHelper
	
	# Generate the top navigation tabs and set a special style for the tab of the current controller
	def navigation_links
		controllers = ['Slides', 'Groups', 'Presentations', 'Displays', 'Schedules']
		admin_controllers = ['Templates', 'Users', 'Events']
		ret = String.new
		base_html_options = {class: 'ui-state-default ui-corner-top'}
		tabs = controllers
		tabs += admin_controllers if current_user.admin?
		tabs.each do |c|
			html_options = {class: 'ui-state-default ui-corner-top'}
			if controller.class.name.include?(c)
				html_options[:class] =	'ui-tabs-active ui-state-active ui-corner-top'
			end
			ret << content_tag('li', link_to(c, {:controller => c.downcase},class: 'ui-tabs-anchor'), html_options)
		end
		return ret.html_safe 
	end
	
	# Inactive toggle button with "led"
	def inactive_toggle(name, status)
		if status
			html="<a class='button inactive led green'>"
		else
			html="<a class='button inactive led off'>"
		end
		html << name << '</a>'
		return html.html_safe
	end
	
	# Active toggle button with a "led"
	def toggle_link_to(name, selected,options = {}, html_options = {})
		html_options[:class] = (selected ? 'button led green' : 'button led off')
		html_options[:title] = (selected ? 'Toggle this off' : 'Toggle this on')
		return link_to name, options, html_options
	end
	
	# Render the authorized users partial with given object
	def authorized_users(obj)
		render :partial => 'shared/authorized_users', :locals => {:obj => obj}
	end

	# FIXME: Use rails4 stuff instead of this and kill this off
	def select_options_tag(name='',select_options={},options={})
		# set selected from value
		selected = ''
		unless options[:value].blank?
			selected = options[:value]
			options.delete(:value)
		end
		select_tag(name,options_for_select(select_options,selected),options)
	end
	
	# Memoize the current user
	def current_user
			@_current_user ||= session[:user_id] &&
				User.includes(:permissions).find_by_id(session[:user_id])
	end

	# Memioze the current event
	def current_event
			@_current_event ||= Event.current
	end
	
end
