# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class Ticket < ActiveRecord::Base
  belongs_to :event
  belongs_to :about, polymorphic: true

  StatusNew = 1
  StatusOpen = 2
  StatusClosed = 3
  StatusCodes = {
    StatusNew => "new",
    StatusOpen => "open",
    StatusClosed => "closed"
  }.freeze
  ValidModels = [Slide, MasterGroup, Presentation, Display].freeze
  Kinds = ["request", "error", "notice"].freeze

  validates :name, presence: true
  validates :status, inclusion: { in: Ticket::StatusCodes }
  validates :kind, inclusion: { in: Ticket::Kinds }
  validates :description, presence: true
  validates :event, presence: true
  validate :check_valid_models

  before_validation :assign_to_current_event, on: :create
  before_update :set_as_open

  scope :current, (-> { where(event_id: Event.current.id).order(status: :asc, updated_at: :asc) })
  scope :open, (-> { where.not(status: StatusClosed) })
  scope :closed, (-> { where status: StatusClosed })

  # Send websocket messages on create and update
  include WebsocketMessages

  include ModelAuthorization

  def status_text
    StatusCodes[status]
  end

  # Used to determinate if a user can close this ticket
  def can_close?(user)
    (status != StatusClosed) && admin?(user)
  end

private

  # Unless the ticket status has been set specificly we will set edited tickets as "open"
  def set_as_open
    self.status = StatusOpen unless changes.include? :status
  end

  # Validation to check that our polymorphic association is of a valid type
  def check_valid_models
    pass = false

    # Having no assigned object is fine
    return if about.blank?

    # Check that the assigned object is in the ValidModels list
    ValidModels.each do |m|
      pass = pass ? true : about.is_a?(m)
    end
    errors.add(:about, "must be a valid object") unless pass
  end

  # Assign the created ticket to the current event
  def assign_to_current_event
    self.event = Event.current if event.blank?
  end
end
