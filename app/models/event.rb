# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class Event < ActiveRecord::Base
  has_many :master_groups
  has_many :presentations
  has_many :schedules
  has_many :slides, through: :master_groups

  serialize :config, Hash

  belongs_to :thrashed, class_name: "ThrashGroup", foreign_key: "thrashed_id"
  belongs_to :ungrouped, class_name: "UnGroup", foreign_key: "ungrouped_id"

  validates :name, uniqueness: true, presence: true
  validates :current, inclusion: { in: [true, false] }
  validates :ungrouped, :thrashed, presence: true
  validates :resolution,
            :schedules_per_slide,
            :schedules_line_length,
            :schedules_tolerance,
            :schedules_time_indent,
            :schedules_event_indent,
            :schedules_font_size,
            :schedules_line_spacing,
            :simple_heading_font_size,
            :simple_heading_x,
            :simple_heading_y,
            :simple_body_margin_left,
            :simple_body_margin_right,
            :simple_body_y, presence: true, numericality: { only_integer: true }
  validates :schedules_subheader_fill,
            presence: true,
            format: {
              with: /\A#(?:[0-9a-f]{3})(?:[0-9a-f]{3})?\z/,
              message: "must be css hex color" }
  validate :ensure_one_current_event

  # Make sure there is only one current event
  before_save :set_current_event

  # Create the associated groups as needed and set their event_id
  before_validation :create_groups, on: :create
  after_create :set_group_event_ids

  # Default config for events
  DefaultConfig = {
    preview: { # Preview image size
      width:  400,
      height: 225
    },
    thumb: { # Small thumbnail size
      width: 128,
      height: 72
    },
    # Simple editor settings
    # FIXME: The default values assume 1920 x 1080 output resolution, need to make better support for 1280x720 defaultss..
    simple: {
      font_sizes: [48, 50, 60, 70, 80, 90, 100, 120, 160, 200, 300, 400],
      colors: ["Gold", "Red", "Orange", "Yellow", "PaleGreen", "Aqua", "LightPink"]
    }
  }.with_indifferent_access

  # Resolutions that are currently supported.
  # Note that the display (eg. iskdpy) also needs to support them.
  SupportedResolutions = [
    [1280, 720],
    [1920, 1080]
  ]

  # Finds the current event
  def self.current
    self.where(current: true).first!
  end

  # Regenerate slide images for all slides in this event.
  # Used after changing the slide image size.
  def generate_images
    self.slides.each do |s|
      s.generate_images_later
    end
  end

  def generate_images_later
    UpdateSlideImagesJob.perform_later self
  end

  #### Per event configuration

  # Read the stored configuration and present it as a hash
  def config
    hash = DefaultConfig

    hash[:full] = {
      width: SupportedResolutions[self[:resolution]].first,
      height: SupportedResolutions[self[:resolution]].last
    }.with_indifferent_access

    hash[:schedules] = {
      time_tolerance: self[:schedules_tolerance],
      events: {
        line_length: self[:schedules_line_length],
        per_slide: self[:schedules_per_slide]
      }.with_indifferent_access,
      slides: {
        font_size: "#{self[:schedules_font_size]}px",
        linespacing: "#{self[:schedules_line_spacing]}%",
        subheader_fill: self[:schedules_subheader_fill],
        indent: {
          time: self[:schedules_time_indent],
          name: self[:schedules_event_indent]
        }.with_indifferent_access
      }.with_indifferent_access,
    }.with_indifferent_access

    hash[:simple][:heading] = {
      font_size: self[:simple_heading_font_size],
      coordinates: [self[:simple_heading_x], self[:simple_heading_y]]
    }.with_indifferent_access

    hash[:simple][:body] = {
      margins: [self[:simple_body_margin_left], self[:simple_body_margin_right]],
      y_coordinate: self[:simple_body_y]
    }.with_indifferent_access

    return hash
  end

  # The configuration options for the simple editor
  # FIXME: True dynamic settings!
  def simple_editor_settings
    settings = self.config[:simple]
    if self.picture_sizes[:full] == SupportedResolutions[1]
      settings[:font_sizes] = [80, 90, 100, 120, 160, 200, 300, 400]
    end
    return settings
  end

  # Set the size for full slide pictures. Checks that the resolution is supported.
  def picture_size=(size)
    if SupportedResolutions.include? size
      self[:resolution] = SupprotedResolutions.index(size)
    else
      raise ArgumentError, "Resolution not supported"
    end
  end

  # Returns a hash containing the set picture sizes.
  def picture_sizes
    h = Hash.new
    [:full, :preview, :thumb].each do |key|
      h[key] = [self.config[key][:width], self.config[key][:height]]
    end
    return h
  end

  # The filename for the background image
  # FIXME: True dynamic setting!
  def background_image
    return "backgrounds/empty.png"
  end

  def prize_template
    SlideTemplate.find(self.config[:prize_template])
  end

private

  # Update the config
  def config=(cnf)
    self[:config] = cnf
  end

  # Create the associated groups as needed
  def create_groups
    self.ungrouped = UnGroup.create(
      name: ("Ungrouped slides for #{name}")
    ) if self.ungrouped.nil?
    self.thrashed = ThrashGroup.create(
      name: ("Thrashed slides for #{name}")
    ) if self.thrashed.nil?
  end

  # Set the event associations on special groups
  def set_group_event_ids
    self.ungrouped.event_id = self.id
    self.ungrouped.save!
    self.thrashed.event_id = self.id
    self.thrashed.save!
  end

  # Callback that resets every other event to non-current when setting another as current one
  def set_current_event
    if self.current && self.changed.include?("current")
      Event.update_all current: false
    end
  end

  # Validation that prevents clearing the current event -bit
  def ensure_one_current_event
    if !self.current && self.changed.include?("current")
      errors.add(:current, "^Must have one current event")
    end
  end
end
