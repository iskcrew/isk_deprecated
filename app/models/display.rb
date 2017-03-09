# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class Display < ActiveRecord::Base
  belongs_to :presentation
  has_one :display_state, autosave: true, dependent: :delete
  has_one :current_group, through: :display_state
  has_one :current_slide, through: :display_state
  has_many :override_queues, -> { order(:position).includes(:slide) }
  has_many :display_counts, dependent: :delete_all

  default_scope { includes(:display_state) }

  validates :name, uniqueness: true, presence: true, length: { maximum: 50 }
  validates :manual, inclusion: { in: [true, false] }
  validates :display_state, presence: true

  before_save :manual_control_checks
  before_validation :create_state, on: :create

  # Timeout before a display is considered as non-responsive
  Timeout = 5 #minutes

  include ModelAuthorization

  # Send websocket messages on create and update
  include WebsocketMessages

  # Ticket system
  include HasTickets

  # Delegations to the display state object, mostly for legacy reasons
  delegate :last_contact_at, :last_contact_at=,                 to: :display_state, allow_nil: true
  delegate :last_hello, :last_hello=,                           to: :display_state, allow_nil: true
  delegate :websocket_connection_id, :websocket_connection_id=, to: :display_state, allow_nil: true
  delegate :current_slide_id, :current_slide_id=,               to: :display_state, allow_nil: true
  delegate :current_group_id, :current_group_id=,               to: :display_state, allow_nil: true
  delegate :ip, :ip=,                                           to: :display_state, allow_nil: true
  delegate :monitor, :monitor=,                                 to: :display_state, allow_nil: true
  delegate :status, :status=,                                   to: :display_state
  delegate :updated_at,                                         to: :display_state, prefix: :state

  alias_method :queue, :override_queues
  alias_method :state, :display_state

  # Used for broadcasting events with callbacks to websocket clients
  def websocket_channel
    return "display_" + self.id.to_s
  end

  # For callback usage
  def displays
    return [self]
  end

  # Adds a slide to override queue for the display
  def add_to_override(slide, duration, effect = Effect.first!)
    oq = self.override_queues.new
    oq.duration = duration
    oq.effect = effect
    oq.slide = slide
    oq.save!
  end

  # Either creates a new display with given name or returns exsisting display
  def self.hello(display_name, display_ip = nil, connection_id = nil)
    display = Display.where(name: display_name).first_or_create
    display.ip = display_ip
    display.websocket_connection_id = connection_id
    display.ping
    display.last_hello = Time.now
    display.save!
    display.status = "running"
    display.state.save!
    return display
  end

  # Remove shown slide from override
  def override_shown(override_id, connection_id = nil)
    begin
      oq = self.override_queues.find(override_id)
      self.ping
      self.websocket_connection_id = connection_id
      self.current_slide = oq.slide
      self.current_group_id = -1
      oq.slide.shown_on self.id, self.live
      oq.destroy
      self.status = "running"
      self.state.save!
      return true
    rescue ActiveRecord::RecordNotFound
      # The override was not found
      self.add_error "Invalid slide in override_shown!"
      return false
    end
  end

  # Set the current group and slide for the display and log the slide as shown
  def set_current_slide(group_id, slide_id, connection_id = nil)
    begin
      if group_id != -1
        self.current_group = self.presentation.groups.find(group_id)
        s = self.current_group.slides.find(slide_id)
        self.current_slide = s
      else
        # Slide is from override
        self.current_group_id = -1
        self.current_slide = Slide.find(slide_id)
      end
      self.ping
      self.websocket_connection_id = connection_id
      self.status = "running"
      self.current_slide.shown_on(self.id, self.live)
      self.state.save!
      return true
    rescue ActiveRecord::RecordNotFound
      # The slide was not found in the presentation
      self.add_error "Invalid slide in set_current slide"
      return false
    end
  end

  # Mark display based on the connection id as disconnected
  def self.disconnect(ws_id)
    if d = Display.joins(:display_state)
                  .where(display_states: { websocket_connection_id: ws_id })
                  .first
      d.status = "disconnected"
      d.websocket_connection_id = nil
      d.save!
      return d
    end
    return nil
  end

  # Relation for all monitored displays that are more than Timeout minutes late
  def self.late
    Display.joins(:display_state).where("display_states.monitor = ? AND display_states.last_contact_at < ?", true, Timeout.minutes.ago)
  end

  # Is this display more than Timeout minutes late?
  def late?
    if self.last_contact_at
      return Time.diff(Time.now, self.last_contact_at, "%m")[:diff].to_i > Timeout
    else
      return false
    end
  end

  # Is the display live, ie. visible to the general audience
  def live?
    self.live
  end

  # Add a error message on this display and set the error state
  # TODO: handle error messages as new error tickets
  def add_error(message)
    if self.error_tickets.open.present?
      t = self.error_tickets.open.last!
      t.description = "#{t.description}\n#{I18n.l(Time.now, format: :iso)} #{message}"
      t.save!
    else
      self.add_error_ticket "#{I18n.l(Time.now, format: :iso)} #{message}"
    end
    self.ping
    self.state.status = "error"
    self.state.save!
  end

  # Returns the time between the last hello and last contact
  # Since the first thing a display does is to say hello this
  # gives the time since last display reboot
  def uptime
    return nil unless self.last_hello && self.last_contact_at

    return Time.diff(self.last_hello, self.last_contact_at, "%h:%m:%s")[:diff]
  end

  # Return a hash containing all associated data, including the slides
  # in the presentation.
  def to_hash
    h = Hash.new
    # Legacy stuff, updated_at used to get touched when anything happened
    if self.state_updated_at > self.updated_at
      h[:updated_at] = self.state_updated_at.to_i
    else
      h[:updated_at] = self.updated_at.to_i
    end

    h[:metadata_updated_at] = self.updated_at.to_i
    h[:state_updated_at] = self.state_updated_at.to_i
    h[:id] = self.id
    h[:name] = self.name
    h[:last_contact_at] = self.last_contact_at.to_i
    h[:manual] = self.manual
    h[:current_slide_id] = self.current_slide_id
    h[:current_group_id] = self.current_group_id
    h[:created_at] = self.created_at.to_i
    h[:presentation] = self.presentation ? self.presentation.to_hash : Hash.new
    q = Array.new
    if self.do_overrides
      self.override_queues.each do |oq|
        q << oq.to_hash
      end
    end
    h[:override_queue] = q
    return h
  end

  def ping
    self.last_contact_at = Time.now
  end

private

  # Create the associated display state as needed
  def create_state
    if self.display_state.nil?
      ds = DisplayState.new
      self.display_state = ds
    end
  end

  # If display is in manual control also stop accepting overrides
  def manual_control_checks
    if self.manual
      self.do_overrides = false
    end
    return true
  end
end
