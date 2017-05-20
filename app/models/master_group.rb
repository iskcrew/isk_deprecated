# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class MasterGroup < ActiveRecord::Base
  has_many :slides, -> { where(deleted: false).order(position: :asc) }, dependent: :destroy
  has_many :groups, dependent: :destroy
  has_many :presentations, -> { uniq }, through: :groups
  has_many :displays, -> { uniq }, through: :presentations
  belongs_to :effect
  belongs_to :event

  validates :name, presence: true, length: { maximum: 100 }
  validates :internal, inclusion: { in: [true, false] }

  # ACL system
  include ModelAuthorization
  # Send websocket messages on create and update
  include WebsocketMessages
  # Allow zipping all associated slide images
  include ZipSlides
  # Ticket system
  include HasTickets
  # Cache sweeper
  include CacheSweeper

  scope :defined_groups, -> { where(internal: false).order("name") }

  # Associate the MasterGroup to a event
  before_create :set_event_id

  # Touch associated displays
  after_save :update_timestamps
  after_destroy :update_timestamps

  # Deal with STI and partial selection etc
  def self.inherited(child)
    child.instance_eval do
      def model_name
        self.base_class.model_name
      end
    end

    child.class_eval do
      def to_partial_path
        "master_groups/master_group"
      end
    end
    super
  end

  def self.ungrouped
    Event.current.ungrouped
  end

  def self.thrashed
    Event.current.thrashed
  end

  def self.current
    self.where(event_id: Event.current.id).where(internal: false)
  end

  def hide_slides
    self.slides.each do |s|
      s.public = false
      s.save!
    end
  end

  def publish_slides
    self.slides.each do |s|
      s.public = true
      s.save!
    end
  end

  # Tag for all cache fragments depending on this master_group
  def cache_tag
    "master_group_#{id}"
  end

private

  def update_timestamps
    touch_by_group(self.id)
  end

  def set_event_id
    self.event = Event.current unless self.event.present?
  rescue ActiveRecord::RecordNotFound
    # In case we don't yet have any events we need to rescue this
    # Otherwise creating the new default event fails.
    self.event_id = 0
  end

  # We need to proganate timestamps down the presentation chain for
  # the dpy, as it updates it's data based on timestamps
  def touch_by_group(group_id)
    d = Display.joins(presentation: :master_groups).where(master_groups: { id: group_id })
    d.update_all(updated_at: Time.now.utc)

    p = Presentation.joins(:master_groups).where(master_groups: { id: group_id })
    p.update_all(updated_at: Time.now.utc)
  end
end
