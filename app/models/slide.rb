# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class Slide < ActiveRecord::Base
  # Callbacks
  after_initialize do |s|
    s.master_group_id = Event.current.ungrouped.id if s.master_group_id.nil?
    true
  end

  # FIXME: we don't really need the filename column...
  after_create do |s|
    s.update_column :filename, "slide_#{s.id}"
  end

  # Touch associated displays
  after_save :update_timestamps
  # If slide is moved to a new group add it to the end of the group
  before_save :check_position

  # Relations
  belongs_to :replacement, class_name: "Slide", foreign_key: "replacement_id"
  belongs_to :master_group, counter_cache: true
  has_many :display_counts
  has_one :event, through: :master_group
  has_many :presentations, (-> { uniq }), through: :master_group

  # Attribute validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :duration,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: -1 }
  validates :master_group, presence: true
  validates :show_clock, :ready, :public, inclusion: { in: [true, false] }

  # Scopes for common queries
  scope :published, (-> { where(public: true) })
  scope :hidden, (-> { where(public: false) })
  scope :current, (-> { where(deleted: false).where(replacement_id: nil) })
  scope :thrashed, (-> { where("replacement_id is not null OR deleted = ?", true) })

  # slide.master_group_name delegation
  delegate :name, to: :master_group, prefix: :master_group

  # Allow sorting of slides in the context of MasterGroups
  include RankedModel
  ranks :position, with_same: :master_group_id, class_name: "Slide"

  # Modules
  # Svg data handling
  include HasSvgData
  # Send websocket messages on create and update
  include WebsocketMessages
  # Ticket system
  include HasTickets
  # ACL system
  include ModelAuthorization
  # Cache sweeper
  include CacheSweeper

  # Constants
  TypeString = "image".freeze
  FilePath = Rails.root.join("data", "slides").freeze
  UsePresentationDelay = -1 # Set duration to this to use presentation setting

  # Error to raise when image operation fails
  class ImageError < StandardError
    # no further implementation necessary
  end

  # We need to set the model names and partial paths on all slides inheriting from Slide
  # If we don't do this we would need to create different partials for each slide type, and handle
  # them in forms
  def self.inherited(child)
    child.instance_eval do
      def model_name
        base_class.model_name
      end
    end

    child.class_eval do
      def to_partial_path
        "slides/slide"
      end
    end
    super
  end

  def publish
    self[:public] = true
  end

  def hide
    self[:public] = false
  end

  # Log that the slide has been shown on display_id just now.
  def shown_on(display_id, live)
    display_counts.create(display_id: display_id, live: live)
  end

  # Create new ungrouped hidden clone of the slide
  def clone!
    new_slide = dup
    new_slide.public = false
    new_slide.name = name.last =~ /\d+/ ? name.next : new_slide.name << " (clone)"
    if new_slide.name.split("(clone)").size > 2
      new_slide.name = new_slide.name.gsub("(clone)", "(badger)") + " (mushroom)"
    elsif new_slide.name.include?("(badger)") && !new_slide.name.include?("(mushroom) (mushroom)")
      new_slide.name = new_slide.name.gsub("(clone)", "(mushroom)")
    elsif new_slide.name.include?("(mushroom) (mushroom)")
      new_slide.name = new_slide.name.gsub("(clone)", "")
    end
    new_slide.position_position = group_position + 1
    new_slide.save!
    FileUtils.copy(data_filename, new_slide.data_filename) if respond_to? :data_filename
    FileUtils.copy(svg_filename, new_slide.svg_filename) if is_svg?
    FileUtils.copy(original_filename, new_slide.original_filename) unless is_svg?
    if ready
      FileUtils.copy(preview_filename, new_slide.preview_filename)
      FileUtils.copy(full_filename, new_slide.full_filename)
      FileUtils.copy(thumb_filename, new_slide.thumb_filename)
    end
    return new_slide
  end

  # Find all displays that have this slide in either their presentation or in their override queues.
  def displays
    displays_via_presentation = Display.joins(presentation: { groups: { master_group: :slides } })
                                       .where(slides: { id: id }).uniq
    return displays_via_presentation.to_a | override.to_a
  end

  # Find all displays that have this slide in their override queues
  def override
    Display.joins(override_queues: :slide).where(slides: { id: id }).uniq
  end

  # Create a hash with the slide metadata
  # This is used for serializing the presentations mostly
  # We check if we have extra selected attributes as follows:
  # group_name - for master_group.name
  # effect_id - for master_group.effect_id
  # presentation_group_id - for the id of the Group belonging to the presentation being serialized
  def to_hash
    hash = Hash.new
    hash[:id] = id
    hash[:name] = name
    hash[:ready] = ready
    hash[:deleted] = deleted
    hash[:created_at] = created_at.to_i
    hash[:updated_at] = updated_at.to_i
    hash[:duration] = duration
    hash[:images_updated_at] = images_updated_at.to_i
    hash[:show_clock] = show_clock
    hash[:type] = is_a?(VideoSlide) ? "video" : "image"
    hash[:master_group] = master_group_id
    if has_attribute? :group_name
      hash[:group_name] = group_name
    else
      hash[:group_name] = master_group.name
    end
    if has_attribute? :effect_id
      ef = effect_id
    else
      ef = master_group.effect_id
    end
    hash[:effect_id] = ef
    hash[:group] = presentation_group_id if has_attribute? :presentation_group_id
    hash[:media_url] = Rails.application.routes.url_helpers.full_slide_path(self)
    hash[:base_url] = Rails.application.routes.url_helpers.slide_path(self)
    return hash
  end
  alias to_h to_hash

  # Used in various views
  def type_str
    self.class::TypeString
  end

  # Is this slide in a real group?
  def grouped?
    !master_group.is_a?(UnGroup)
  end

  # Has this slide been replaced by another slide?
  def replaced?
    !replacement.nil?
  end

  # Is this a svg based slide?
  def is_svg?
    is_svg
  end

  # Replace this slide with another slide
  def replace!(slide)
    self.replacement = slide
    slide.position = position
    slide.master_group = master_group
    slide.save!
    destroy
  end

  # The position of this slide inside a group
  def group_position
    Slide.where(master_group_id: master_group_id).where("position < ?", position).count
  end

  # Generate the various different sized images from the slide master image
  def generate_images
    if generate_full_image
      generate_previews
      self.images_updated_at = Time.now
    end

    self.ready = true
    save!
  end

  def generate_images_later
    UpdateSlideImagesJob.perform_later self
  end

  # Filenames of different sized slide images
  def thumb_filename
    FilePath.join("#{filename}_thumb.png")
  end

  def preview_filename
    FilePath.join("#{filename}_preview.png")
  end

  def full_filename
    FilePath.join("#{filename}_full.png")
  end

  def original_filename
    FilePath.join("#{filename}_original")
  end

  # Override the default destroy method to soft-delete slides
  def destroy
    self.deleted = true
    self.master_group = Event.current.thrashed
    save!
  end

  # Mark the slide as not deleted.
  def undelete
    self.deleted = false
    self.master_group = Event.current.ungrouped
    save!
  end

  # Send websocket-messages when a slides images have been updated
  def updated_image_notifications
    msg = IskMessage.new("slide", "updated_image", to_hash)
    msg.send
  end

  # Cache tag for all fragments depending on this slide
  def cache_tag
    "slide_#{id}"
  end

  # Cache key for info fragment with full edit priviledges
  def rw_cache_key
    "#{cache_tag}_edit"
  end

  # Cache key for info fragment with hide priviledge
  def hide_cache_key
    "#{cache_tag}_hide"
  end

  # Cache key for info fragment with no edit priviledges
  def ro_cache_key
    "#{cache_tag}_ro"
  end

  # Convenience method of getting the configured picture sizes of
  # the current event.
  def self.picture_sizes
    Event.current.picture_sizes
  end

private

  # The picture dimensions
  def picture_sizes
    @_picture_sizes ||= event.picture_sizes
  end

  # Create the preview images from the full size slide image
  def generate_previews
    system resize_command(preview_filename, picture_sizes[:preview])
    system resize_command(thumb_filename, picture_sizes[:thumb])
  end

  # Shell command to resize the full sized slide image to requested size.
  # Size should be a array like [width, height]
  def resize_command(file, size)
    "convert #{full_filename} -resize #{size.join('x')} #{file}"
  end

  # Generate the full size slideimage from svg with inkscape
  def inkscape_command_line(tmp_file)
    size = picture_sizes[:full]
    # Chance to proper directory
    command = "cd #{Slide::FilePath} && inkscape"
    # Export size
    command << " -w #{size.first} -h #{size.last}"
    # Export to file
    command << " -e #{tmp_file.path} #{svg_filename}"
    # Supress std-out reporting
    command << " 2>&1"

    return command
  end

  # Compare the passed file against the current slide image.
  # If they differ then copy the tmp_file image as the new slide image.
  # TODO: Should we be extra careful and validate the image?
  def compare_new_image(tmp_file)
    if File.exist?(full_filename) && FileUtils.compare_file(tmp_file.path, full_filename)
      # Generated image is the same as the previous one
      tmp_file.unlink
      return false
    else
      FileUtils.mv tmp_file.path, full_filename
      # Tmpfile has 700 mode, we need to give other read permissions (mainly the web server)
      FileUtils.chmod 0o0644, full_filename
      return true
    end
  end

  # If slides group has been changed move it to the end of the new group
  def check_position
    self.position_position = :last if changed.include? "master_group_id"
  end

  # Update timestamps of all associated objects
  def update_timestamps
    touch_by_group(master_group_id)
    touch_by_group(master_group_id_was) if changed.include? "master_group_id"
  end

  # We need to proganate timestamps down the presentation chain for
  # the dpy, as it updates it's data based on timestamps
  def touch_by_group(group_id)
    # Touch displays
    d = Display.joins(presentation: :master_groups).where(master_groups: { id: group_id })
    d.update_all(updated_at: Time.now.utc)
    # Touch presentations
    p = Presentation.joins(:master_groups).where(master_groups: { id: group_id })
    p.update_all(updated_at: Time.now.utc)
    # Touch groups
    MasterGroup.where(id: group_id).update_all(updated_at: Time.now.utc)
  end
end
