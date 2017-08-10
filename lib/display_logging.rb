# frozen_string_literal: true

#
#  display_logging.rb
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-06-14.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#
# Handles the logging of iskdpy communications to a separate file.
#
# The events come from DisplaysController#websocket

class DisplayLogging
  @_logger = nil

  # Initialize the logger for displays
  def self.logger
    unless @_logger.present?
      @_logger = Logger.new(Rails.root.join("log", "displays.log"))
      @_logger.datetime_format = "%Y-%m-%dT%H:%M:%S"
      @_logger.formatter = proc do |severity, datetime, _progname, msg|
        "#{datetime} - #{severity}: #{msg}\n"
      end
    end

    return @_logger
  end

  # Use custom logger
  def self.logger=(logger)
    @_logger = logger
  end

  # Log a action in the display communication protocol
  def self.log_display_event(start, finish, payload)
    time = finish - start
    msg = payload[:message]
    log_msg = []
    log_msg << payload[:type].to_s
    log_msg << "From #{payload[:ip]}"
    log_msg << "Display name: #{payload[:display_name]}" if payload[:display_name]
    log_msg << "Time taken: #{(time * 1000).round(2)}ms"
    log_msg << "Command: #{msg.type}"
    log_msg << "Parameters: #{msg.payload}"

    if payload[:exception].present?
      log_msg << "EXCEPTION: #{payload[:exception].first}"
      log_msg << payload[:exception].last
      logger.error log_msg.join("\n\t")
    else
      logger.info log_msg.join("\n\t")
    end
  end

  # Subscribe to the iskdpy notifications
  ActiveSupport::Notifications.subscribe("iskdpy") do |_name, start, finish, _id, payload|
    log_display_event(start, finish, payload)
  end
end
