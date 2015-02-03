# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class ScheduleSlide < SvgSlide
	#Automatically generated schedule slide
	TypeString = 'schedule'
		
	# FIXME: proper settings
	SubheaderX = 50
	SubheaderFill = '#e2e534'
	TimeIndent = 50
	ItemNameIndent = TimeIndent + 230
	ItemSpacing = 80
	FontSize = '72px'
	
	# Find the schedule this slide belongs to
	def schedule
		Schedule.joins(:slidegroup).where(master_groups: {id: self.master_group_id}).first ||
		Schedule.joins(:up_next_group).where(master_groups: {id: self.master_group_id}).first
	end
	
	# Create the slide svg from passed schedule events
	def create_svg(header, items)
		self.name = header
		svg = Nokogiri::XML(SimpleSlide.create_svg({heading: header}))
		
		body = svg.at_css(SimpleSlide::BodySelector)
		body.children.each do |c|
			c.remove
		end

		body['sodipodi:linespacing'] = '100%'
		
		items.each do |item|
			row = Nokogiri::XML::Node.new 'tspan', body
			row['sodipodi:role'] = 'line'
			row['font-size'] = FontSize
			
			if item[:subheader]
				tspan = Nokogiri::XML::Node.new 'tspan', row
				tspan['fill'] = SubheaderFill
				tspan.content = item[:subheader]
				row.add_child tspan
			else
				# Time
				tspan_time = Nokogiri::XML::Node.new 'tspan', row
				tspan_time['x'] = body['x'].to_i + TimeIndent
				tspan_time.content = item[:time]
				row.add_child tspan_time
				
				# name
				tspan_name = Nokogiri::XML::Node.new 'tspan', row
				tspan_name['x'] = body['x'].to_i + ItemNameIndent
				tspan_name.content = item[:name]
				row.add_child tspan_name
			end
			body.add_child row
		end
		
		self.svg_data = svg.to_xml
	end

	private

	def schedule_row(row, item)
		
	end

end