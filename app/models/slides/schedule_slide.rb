# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class ScheduleSlide < SvgSlide
  # Automatically generated schedule slide
  TypeString = "schedule".freeze

  # Find the schedule this slide belongs to
  def schedule
    Schedule.joins(:slidegroup).where(master_groups: { id: master_group_id }).first ||
    Schedule.joins(:next_up_group).where(master_groups: { id: master_group_id }).first
  end

  # Create the slide svg from passed schedule events
  def create_svg(header, items)
    self.name = header
    svg = Nokogiri::XML(SimpleSlide.create_svg(heading: header))

    body = svg.at_css(SimpleSlide::BodySelector)
    body.children.each(&:remove)

    body["sodipodi:linespacing"] = settings[:linespacing]

    items.each do |item|
      row = Nokogiri::XML::Node.new "tspan", body
      row["sodipodi:role"] = "line"
      row["font-size"] = settings[:font_size]

      if item[:subheader]
        tspan = Nokogiri::XML::Node.new "tspan", row
        tspan["fill"] = settings[:subheader_fill]
        tspan.content = item[:subheader]
        row.add_child tspan
      else
        # Time
        tspan_time = Nokogiri::XML::Node.new "tspan", row
        tspan_time["x"] = body["x"].to_i + settings[:indent][:time]
        tspan_time.content = item[:time]
        row.add_child tspan_time

        # name
        tspan_name = Nokogiri::XML::Node.new "tspan", row
        tspan_name["x"] = body["x"].to_i + settings[:indent][:name]
        tspan_name.content = item[:name]
        row.add_child tspan_name
      end
      body.add_child row
    end

    self.svg_data = svg.to_xml
  end

private

  def settings
    @_settings ||= schedule.settings[:slides]
  end
end
