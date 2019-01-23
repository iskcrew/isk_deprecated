#!/usr/bin/env ruby
# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

# This script collects some ISK statistics in rrd databases

require File.expand_path(File.join(File.dirname(__FILE__), "..", "config", "environment"))
require "colorize"
require "rrd"
require "daemons"
require_relative "../lib/cli_helpers.rb"
require_relative "../lib/rrd_helpers.rb"

@pid_path = Pathname.new File.expand_path("../../tmp/pids", __FILE__)
@rrd_path = Pathname.new File.expand_path("../../data/rrd", __FILE__)
@log_path = Pathname.new File.expand_path("../../log", __FILE__)
@wpe_key = Pathname.new File.expand_path("../../config/wpe_key", __FILE__)

options = {
  app_name: "rrd_monitoring",
  dir_mode: :normal,
  dir: @pid_path.to_s,
  log_dir: @log_path.to_s
}

Daemons.run_proc("rrd_monitoring", options) do
  Daemonize.redirect_io @log_path.join "rrd_monitoring.log"

  say "RRD monitoring daemon started"

  # Collect pid files
  loop do
    servers = Dir[@pid_path.join("server*")].collect { |f| extract_pid(f) }
    resque =  Dir[@pid_path.join("resque*")].collect { |f| extract_pid(f) }
    background_jobs = Dir[@pid_path.join("background_jobs*")].collect { |f| extract_pid(f) }

    print "Collecting servers: "
    servers.each_with_index do |pid, i|
      print "X"
      rrd_file = @rrd_path.join("server_#{i}.rrd").to_s
      rrd = create_rrd_for_process rrd_file
      rrd.update Time.now, *get_process_stats(pid)
    end
    print "\n"

    print "Collecting background workers: "
    resque.each_with_index do |pid, i|
      print "X"
      rrd_file = @rrd_path.join("resque_#{i}.rrd").to_s
      rrd = create_rrd_for_process rrd_file
      rrd.update Time.now, *get_process_stats(pid)
    end
    print "\n"

    print "Timed background jobs worker: "
    background_jobs.each_with_index do |pid, i|
      print "X"
      rrd_file = @rrd_path.join("background_job_#{i}.rrd").to_s
      rrd = create_rrd_for_process rrd_file
      rrd.update Time.now, *get_process_stats(pid)
    end
    print "\n"

    print "WPE displays: "
    # Monitor WPE displays
    ActiveRecord::Base.connection.clear_query_cache
    Display.where(wpe: true).each do |d|
      print "X"
      rrd_file = @rrd_path.join("wpe_#{d.id}.rrd").to_s
      rrd = create_rrd_for_wpe rrd_file
      collect_wpe_stats(d, @wpe_key, rrd)
    end
    print "\n"

    puts "Sleeping..."
    sleep(30)
  end
end
