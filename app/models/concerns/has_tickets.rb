# frozen_string_literal: true

#
#  has_tickets.rb
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-07-13.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#
# A general module for all models that support opening tickets on them

module HasTickets
  extend ActiveSupport::Concern

  included do
    has_many :tickets, as: :about
  end

  # Define class methods for the model including this
  module ClassMethods
    # Return all records with error tickets
    def with_error_tickets
      joins(:tickets)
        .where(tickets: { kind: "error" })
        .where.not(tickets: { status: Ticket::StatusClosed })
    end
  end

  # Add a new error ticket on this object with given message
  def add_error_ticket(message)
    t = Ticket.new(kind: "error")
    t.about = self
    t.name = "Error in #{self.class.name}: #{name}"
    t.description = message
    t.save!
  end

  def error_tickets
    tickets.where(kind: "error")
  end
end
