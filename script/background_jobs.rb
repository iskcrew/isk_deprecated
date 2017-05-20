#!/usr/bin/env ruby
# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md
require File.expand_path(File.join(File.dirname(__FILE__), "..", "config", "environment"))
require "net/http"
require_relative "../lib/cli_helpers.rb"

Sleep = 3.minutes # Sleep for 3 minutes between loops

@pid_path = Pathname.new File.expand_path("../../tmp/pids", __FILE__)
@log_path = Pathname.new File.expand_path("../../log", __FILE__)

options = {
  app_name: "background_jobs",
  dir_mode: :normal,
  dir: @pid_path.to_s,
  log_dir: @log_path.to_s,
}

Daemons.run_proc("background_jobs", options) do
  Daemonize.redirect_io @log_path.join "background_jobs.log"
  say "Daemon started"

  # daemonizing the process closes the log files, so set new loggers
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveRecord::Base.logger.level = Logger::WARN

  Rails.logger = Logger.new(STDOUT)
  Rails.logger.level = Logger::WARN

  Resque.logger = Logger.new(STDOUT)
  ActiveJob::Base.logger = Logger.new(STDOUT)
  ActiveJob::Base.logger.level = Logger::WARN

  ActiveRecord::Base.connection.reconnect!

  loop do
    say "Fetching http-slides.."
    begin
      realtime = Benchmark.realtime do
        @slides = Event.current.slides.where(type: "HttpSlide").all.each do |slide|
          slide.fetch!
        end
      end
      say " -> Fetched #{@slides.size} slides in %.2f seconds (%.2f sec. per slide)" % [realtime, realtime / @slides.size]
    rescue Exception => e
      say "Error fetching http-slides"
      puts e.message
      puts e.backtrace.inspect
    end
    @slides = nil

    say "Generating schedule slides.."
    begin
      realtime = Benchmark.realtime do
        @schedules = Event.current.schedules.all.each do |schedule|
          schedule.generate_slides
        end
      end
      say(" -> Generated #{@schedules.size} schedules in %.2f seconds (%.2f sec. per schedule)" % [realtime,  realtime / @schedules.size])
    rescue Exception => e
      say "Error generating schedule slides"
      puts e.message
      puts e.backtrace.inspect
    end
    @schedules = nil

    say "Sleeping for #{Sleep} seconds"
    sleep(Sleep)
  end
end
