# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class SimpleSlide < SvgSlide
  TypeString = "simple"

  # Slidedata functionality
  DefaultSlidedata = {
    heading: "Slide heading",
    text: "Slide contents with <highlight>",
    color: "Red",
    text_size: 48,
    text_align: "Left"
  }.with_indifferent_access.freeze

  include HasSlidedata

  BaseTemplate = Rails.root.join("data", "templates", "simple.svg").freeze
  HeadingSelector = "text#header"
  BodySelector = "text#slide_content"
  BackgroundSelector = "image#background_picture"
  Colors = ["Gold", "Red", "Orange", "Yellow", "PaleGreen", "Aqua", "LightPink"].freeze

  validate :check_color

  # If our slidedata chances mark the slide as not ready when saving it.
  before_save do
    if @_slidedata.present? || !File.exist?(svg_filename)
      self.svg_data = SimpleSlide.create_svg(slidedata)
      self.ready = false
    end
    true
  end

  def self.copy!(s)
    orig_id = s.id

    simple = s.dup
    simple.save!
    simple.reload

    FileUtils.copy(s.svg_filename, simple.svg_filename)

    raise Slide::ConvertError unless simple.to_simple_slide!

    simple = SimpleSlide.find(simple.id)

    s = Slide.find(orig_id)
    s.replacement_id = simple.id

    return simple
  end

  # TODO: migrate to nokogiri
  def self.create_from_svg_slide(svg_slide)
    raise Slide::ConvertError unless svg_slide.is_a? SvgSlide

    simple = SimpleSlide.new
    simple.name = svg_slide.name + " (converted)"
    simple.ready = false
    simple.show_clock = svg_slide.show_clock

    svg = Nokogiri.XML(svg_slide.svg_data)

    # IF slide has other images than the background we have a problem
    raise Slide::ConvertError if svg.css("image").count != 1

    text_nodes = svg.css("text")

    # The slide needs to contain some text
    raise Slide::ConvertError unless text_nodes.count.positive?

    header = text_nodes.first.text
    text_nodes.shift

    text = String.new
    text_nodes.each do |n|
      text << n.text
    end
    text.strip!

    simple.slidedata = { heading: header, text: text }
    simple.ready = false
    simple.save!

    return simple
  end

  def clone!
    new_slide = super
    new_slide.slidedata = slidedata
    return new_slide
  end

  # Take in the slide data and create a svg using them
  # This is used both to save the slide and to display a preview
  # in the simple editor page via websocket calls
  # TODO: create inkscape compliant svg!
  def self.create_svg(options)
    text_align = options[:text_align] || DefaultSlidedata[:text_align]
    text_size = options[:text_size] || DefaultSlidedata[:text_size]
    color = options[:color] || DefaultSlidedata[:color]
    heading = options[:heading] || ""
    text = options[:text] || ""

    current_event = Event.current
    settings = current_event.simple_editor_settings
    size = current_event.picture_sizes[:full]

    svg = prepare_template(settings, size, current_event.background_image)

    head = svg.at_css(HeadingSelector)
    set_text(head, heading, settings[:heading][:coordinates].first, color, settings[:heading][:font_size])

    # Find out the text x coordinate
    text_x = row_x(text_align, settings[:body][:margins])
    body = svg.at_css(BodySelector)
    set_text(body, text, text_x, color, text_size, text_align)

    return svg.to_xml
  end

private

  # Private singleton methods
  class << self
  private

    # Prepare the base template based on event config
    def prepare_template(settings, size, background_image)
      svg = Nokogiri::XML(File.open(BaseTemplate))

      # Add sodipodi namespace
      svg.root.add_namespace "sodipodi", "http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"

      # Set dimensions
      svg.root["width"] = size.first
      svg.root["height"] = size.last

      # Set viewbox
      svg.root["viewBox"] = "0 0 #{size.first} #{size.last}"

      # Set background
      bg = svg.at_css(BackgroundSelector)
      bg["xlink:href"] = background_image
      bg["x"] = 0
      bg["y"] = 0
      bg["width"] = size.first
      bg["height"] = size.last

      # Position header
      header = svg.at_css(HeadingSelector)
      header["x"] = settings[:heading][:coordinates].first
      header["y"] = settings[:heading][:coordinates].last

      # Header font size
      header["font-size"] = settings[:heading][:font_size]

      # Position body
      body = svg.at_css(BodySelector)
      body["y"] = settings[:body][:y_coordinate]

      # Clear child elements from header and body
      clear_childs(header)
      clear_childs(body)

      # Set guides
      named_view = svg.at_css("sodipodi|namedview")
      named_view.css("sodipodi|guide").each(&:remove)

      # Vertical guides
      [
        "#{settings[:body][:margins].first},0",
        "#{settings[:body][:margins].last},0",
        "#{settings[:heading][:coordinates].first},0"
      ].each do |coord|
        named_view.add_child(create_guide(svg, coord, "-200,0"))
      end

      # Horizontal guides
      [
        "0,#{size.last - settings[:body][:y_coordinate]}",
        "0,#{size.last - settings[:heading][:coordinates].last}"
      ].each do |coord|
        named_view.add_child(create_guide(svg, coord, "0,-200"))
      end

      return svg
    end

    # Create a new sodipodi:guide element
    def create_guide(svg, position, orientation)
      guide = Nokogiri::XML::Node.new("sodipodi:guide", svg)
      guide["position"] = position
      guide["orientation"] = orientation
      return guide
    end

    def set_text(element, text, text_x, color = nil, size = nil, align = nil)
      # Set default attributes
      element["x"] = text_x
      element["sodipodi:linespacing"] = "100%"
      if size
        element["font-size"] = size
      else
        size = element["font-size"]
      end

      first_line = true

      text.each_line do |l|
        row = Nokogiri::XML::Node.new "tspan", element
        row["sodipodi:role"] = "line"
        row["font-size"] = size
        row["x"] = text_x

        # Set the line spacing. First line has no spacing, others have 1em spacing.
        if first_line
          first_line = false
        else
          row["dy"] = "1em"
        end
        if l.strip.empty?
          row["font-size"] = (size.to_i * 0.4).to_i
          row["fill-opacity"] = 0
          row["stroke-opacity"] = 0
          row.content = "a"
          element.add_child row
          next
        end
        parts = l.split(/<([^>]*)>/)
        parts.each_index do |i|
          ts = Nokogiri::XML::Node.new "tspan", row
          ts["fill"] = color if color && i.odd?
          ts.content = parts[i].chomp
          row.add_child ts
        end
        element.add_child row
      end

      return set_text_anchor(element, align)
    end

    def row_x(align, margins)
      return margins.first unless align

      case align.strip.downcase
      when "right"
        return margins.last
      when "centered"
        return (margins.first + margins.last) / 2
      else
        return margins.first
      end
    end

    # Clear child elements
    def clear_childs(e)
      # Clear child elements (delete_element deletes only one element)
      e.children.each(&:remove)
      e.content = ""

      return e
    end

    def set_text_anchor(element, align)
      if align
        case align.strip.downcase
        when "right"
          text_anchor = "end"
        when "centered"
          text_anchor = "middle"
        else
          text_anchor = "start"
        end
        element["text-anchor"] = text_anchor
      end
      return element
    end
  end

  # Validate that the highlight color is ok
  def check_color
    # Do not run this validation if slidedata hasn't been changed or loaded, as doing so will mark the slide as not ready
    return true if @_slidedata.nil?
    unless Event.current.config[:simple][:colors].include? slidedata[:color]
      errors.add :color, "is not whitelisted"
    end
  end
end
