# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class SlideTemplate < ActiveRecord::Base
  belongs_to :event
  has_many :fields, -> { order(field_order: :asc) }, class_name: "TemplateField"
  has_many :slides, foreign_key: :foreign_object_id

  validates :name, :event, presence: true

  after_create :write_template
  before_validation :assign_to_event, on: :create

  accepts_nested_attributes_for :fields, reject_if: :reject_new_fields

  FilePath = Rails.root.join("data", "templates")

  scope :current, -> { where deleted: false }

  # Load the svg in
  def template
    return @_template if (@_template || new_record?)
    @_template = File.read(filename) if File.exist?(filename)

    return @_template
  end

  # Set the template svg and process it
  # FIXME: Validate that new template has the same editable fields present!
  def template=(svg)
    @_template = svg
    process_svg
    write_template
  end

  # Handle a uploaded file
  def upload=(upload)
    self.template = upload.read
  end

  # TODO: input validation
  def generate_svg(data)
    svg = REXML::Document.new(template)

    fields.editable.each do |f|
      svg.root.elements.each("//text[@id='#{f.element_id}']") do |e|
        set_text(e, data[f.element_id.to_sym], f.color)
      end
    end

    return svg.to_s
  end

  # Filename to store the svg template file in
  def filename
    FilePath.join "slide_template_#{id}.svg"
  end

  # We use soft-delete for templates, because hard-deleting the template will break all slides using it.
  def destroy
    self.deleted = true
    save!
  end

private

  # Associate a new SlideTemplate to Event when it's created
  def assign_to_event
    self.event = Event.current if event.nil?
    return true
  end

  # Filter for nested parameters preventing creation of new fields
  def reject_new_fields(a)
    a[:id].blank?
  end

  # Process the uploaded svg template
  # 1. We need to set the viewBox attribute for browser-scaling to work
  # 2. Extract the <text> elements and generate the associated template_Fields from that list
  # FIXME: remove rexml in favor of nokogiri
  def process_svg
    svg = REXML::Document.new(@_template)
    svg = set_viewbox(svg)
    generate_settings(svg)
    @_template = svg.to_s
  end

  # Set the viewBox attribute on the base svg
  # Inkscape doesn't set this and we need it for browser previews to work
  def set_viewbox(svg)
    width = svg.root.attributes["width"].to_i
    height = svg.root.attributes["height"].to_i
    svg.root.attributes["viewBox"] = "0 0 #{width} #{height}"
    return svg
  end

  # Extract all text fields from the svg template
  def generate_settings(svg)
    svg.root.elements.each("//text") do |e|
      f = fields.new
      f.element_id = e.attributes["id"]
      f.default_value = REXML::XPath.match(e, ".//text()").join.strip
      f.save!
    end
  end

  # Store the template in a file
  # we use binary mode here to prevent ascii conversions..
  # FIXME: set viewBox on import, so web preview scales properly!
  def write_template
    return if new_record?
    File.open(filename, "wb") do |f|
      f.write @_template
    end
  end

  def set_text(element, text, color)
    # Clear tspans
    element.elements.each do
      element.delete_element("*")
    end

    element.text = ""

    first_line = true

    text.each_line do |l|
      row = element.add_element "tspan"
      row.attributes["x"] = element.attributes["x"]
      row.attributes["sodipodi:role"] = "line"
      row.attributes["xml:space"] = "preserve"

      # First line requires little different attributes
      if first_line
        first_line = false
      else
        row.attributes["dy"] = "1em"
      end

      parts = l.split(/<([^>]*)>/)
      parts.each_index do |i|
        ts = row.add_element "tspan"
        ts.attributes["fill"] = color if color && i.odd
        ts.text = parts[i]
      end
    end
  end
end
