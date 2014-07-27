# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


module SlidesHelper
	
	# Extract value for a input for a template slide
	def template_slide_value(slide, field)
		if slide.respond_to? :slidedata
			return slide.slidedata[field.element_id]
		else
			return field.default_value
		end
	end
	
	# Cache key for user-dependant slide info block
	def slide_key(slide)
		slide.cache_key + current_user.cache_key
	end
	
	# Render the slide duration as text
	def slide_duration(slide)
		if slide.duration == -1
			return 'Using presentation default'
		elsif slide.duration == 0
			return 'Infinite'
		else
			return slide.duration.to_s + " seconds"
		end
	end
	
	# <img> tag for the slide preview image
	# FIXME: DRY with other images
	def slide_preview_image_tag(slide)
		html_options = {
			:class => 'preview ' + (slide.public ? 'slide-public' : 'slide-hidden'),
			:id => 'slide_preview_' + slide.id.to_s
		}
		
		if slide.ready
			url = url_for(:controller => :slides, :action => :preview, :id => slide.id, :t => slide.images_updated_at.to_i)
		else
			url = '/wait.gif'
		end
		
		return image_tag url, html_options
		
	end

	# <img> tag for the slide thumbnail
	# FIXME: DRY with other images
	def slide_thumb_image_tag(slide)
		html_options = {
			:class => 'thumb ' + (slide.public ? 'slide-public' : 'slide-hidden'),
			:id => 'slide_thumb_' + slide.id.to_s
		}
		if slide.ready
			url = url_for(:controller => :slides, :action => :thumb, :id => slide.id, :t => slide.images_updated_at.to_i)
		else
			url ='/wait.gif'
		end
		return image_tag url, html_options
	end

	# <img> tag for the slide full image
	def slide_full_image_tag(slide)
		image_tag url_for(controller: :slides, action: :full, id: slide.id, t: slide.images_updated_at.to_i),
		 {class: 'full_slide', id: 'slide_full_' + slide.id.to_s}
	end
	
	# link to slide#show with the preview image
	# FIXME: DRY with other images
	def slide_preview_to_show_tag(slide)
		html_options = {
			:title => 'Click to show slide details',
			:class => 'slide-preview-to-show'
		}
		url_options = {
			:controller => :slides,
			:action => :show,
			:id => slide.id
		}
		return link_to slide_preview_image_tag(slide), url_options, html_options
	end

	# link to slide#show with the thumb image
	# FIXME: DRY with other images
	def slide_thumb_to_show_tag(slide)
		html_options = {
			:title => 'Click to show slide details',
			:class => 'slide-preview-to-show'
		}
		url_options = {
			:controller => :slides,
			:action => :show,
			:id => slide.id
		}
		return link_to slide_thumb_image_tag(slide), url_options, html_options
	end

	# link to slide#full with the preview image
	def slide_preview_to_full_tag(slide)
		html_options = {
			title: 'Click to show full size slide image',
			class: 'slide-preview-to-full'
		}
		url_options = {
			controller: :slides,
			action: :full,
			id: slide.id
		}
		return link_to slide_preview_image_tag(slide), url_options, html_options
	end
	
	# Helpers used for generating the simple editor widgets
	def simple_color_select(f, color)
		f.select :color, options_for_select(simple_colors, color), {}, id: 'simple_color', data: {simple_Field: true}
	end
	
	def simple_text_size_select(f, size)
		f.select :text_size, options_for_select(simple_text_sizes, size),	 {}, id: 'simple_text_size', data: {simple_field: true}
	end
	
	def simple_text_align_select(f, align)
		f.select :text_align, options_for_select(simple_aligns, align), {}, id: 'simple_text_align', data: {simple_field: true}
	end
	
	# A button to hide the slide or just inactive toggle, depending on user permissions
	def slide_hide_button_or_status(s, remote = false)
		if s.can_edit? current_user
			return slide_toggle_button('Public', s, :public)
		elsif s.can_hide?(current_user) && s.public == true
			return toggle_link_to 'Public', s.public, hide_slide_path(s), 
				method: :post, remote: true, 
				data: {confirm: "Are you sure you want to hide this slide? You cannot publish it later!"}
		else
			return inactive_toggle('Public', s.public)
		end
	end
	
	# Generic toggle button to toggle some boolean on the slide
	# FIXME OLD STYLE LINK PARAMETERS
	def slide_toggle_button(name, slide, attrib)
		toggle_link_to name, slide.send(attrib), {:controller => :slides, :action => :update, :id => slide.id, :slide => {attrib => !slide.send(attrib)}}, :method => :put, :remote => true
	end
	
	# Generate the edit link with consistent confirm message
	def slide_edit_link(slide)
		link_text = "#{icon 'edit'} Edit".html_safe
		link_to link_text, edit_slide_path(slide), 
			:class => 'button', title: 'Edit slide metadata', data: {confirm: (
			slide.public ? 'This is a public slide, are you sure you want to edit it?' : nil)}
	end
	
	# Generate the download svg link for the slide with consistent confirm message
	def slide_svg_link(slide)
		if [InkscapeSlide].include? slide.class
			link_text = "#{icon 'download'} SVG".html_safe
			link_to link_text, {controller: :slides, action: :svg_data, id: slide.id},
							 class: 'button', title: 'Download slide in SVG format', data: {confirm: (
						 		slide.public ? 'This is a public slide, are you sure you want to edit it?' : nil)}
		end
	end
	
	# Generate the slide clone button with tooltip
	def slide_clone_button(slide)
		link_to "#{icon 'copy'} Clone".html_safe, {:controller => :slides, :action => :clone, :id => slide.id},
							:method => :post, :title => 'Create clone of this slide', :class => 'button'
	end
	
	# Generate the slide delete button setting the tooltip and confirm message
	def slide_delete_button(slide)
		link_to "#{icon 'times-circle'} Delete".html_safe, slide_path(slide),
							data: {confirm: "Are you sure?"}, title: 'Mark this slide as deleted, you can undo later',
							method: :delete, class: 'button warning'
	end
	
	# Ungroup slide button
	def slide_ungroup_button(slide)
		link_to 'Ungroup', {:controller => :slides, :action => :ungroup, :id => slide.id},
							 :method => :post, :class => 'button ungroup'
	end
	
	# Link to next slide in the same group as this slide
	def slide_next_in_group_link(slide)
		if s = slide.master_group.slides.where("position > #{slide.position}").first
			link_to ("Next slide #{icon('forward')}").html_safe, slide_path(s), class: 'button'
		end
	end

	# Link to previous slide in the same group as this slide
	def slide_previous_in_group_link(slide)
		if s = slide.master_group.slides.where("position < #{slide.position}").first
			link_to ("#{icon('backward')} Previous slide").html_safe, slide_path(s), class: 'button'
		end
	end

	
	# Turn the slide class into human readable slide type
	def slide_class(s)
		return 'Template slide' if s.is_a? TemplateSlide
		return 'Inkscape slide' if s.is_a? InkscapeSlide
		return 'Online simple editor slide' if s.is_a? SimpleSlide
		return 'Online SVG-editor slide' if s.is_a? SvgSlide
		return 'Video presentation' if s.is_a? VideoSlide
		return 'Automatically updating Http-slide' if s.is_a? HttpSlide
		return 'Plain bitmap slide' if !s.is_svg?
		return 'Unknown'
	end
	
	# Links for filtering the slide list on slides#index
	def slide_filter_links(filter)
		html = String.new
		html << link_to('All slides', {:action => :index}, :class => (filter ? nil : 'current'))
		html << link_to('Thrashed', {:action => :index, :filter => 'thrashed'}, :class => (filter == :thrashed ? 'current' : nil))

		return html.html_safe
	end
	
	private
	
	# Colors for the simple editor
	def simple_colors
		double_array ['Gold', 'Red', 'Orange', 'Yellow', 'PaleGreen', 'Aqua', 'LightPink']
	end
	
	# Text align options for the simple editor
	def simple_aligns
		double_array ['Left', 'Left Centered', 'Centered', 'Right Centered', 'Right']
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
		v.each do |v|
			ret << [v,v]
		end
		return ret
	end
end
