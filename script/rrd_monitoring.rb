#!/usr/bin/env ruby

# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

# This script collects some ISK statistics in rrd databases

require "rubygems"

# Set up gems listed in the Gemfile.
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)
require "bundler/setup" if File.exist?(ENV["BUNDLE_GEMFILE"])
require "colorize"
require "rrd"
require "daemons"
require_relative "../lib/cli_helpers.rb"

@pid_path = Pathname.new File.expand_path("../../tmp/pids", __FILE__)
@rrd_path = Pathname.new File.expand_path("../../data/rrd", __FILE__)
@log_path = Pathname.new File.expand_path("../../log", __FILE__)

options = {
  app_name: "rrd_monitoring",
  dir_mode: :normal,
  dir: @pid_path.to_s,
  log_dir: @log_path.to_s,
}

Daemons.run_proc("rrd_monitoring", options) do
  Daemonize.redirect_io @log_path.join "rrd_monitoring.log"

  say "RRD monitoring daemon started"

  def get_process_stats(pid)
    mem, cpu = `ps -o rss= -o %cpu= -p #{pid}`.split
    return mem.to_i * 1024, cpu.to_f
  end

  def extract_pid(f)
    pid = File.read(@pid_path.join(f).to_s).to_i

    # Check if the pid is running
    return pid if system "ps -p #{pid} 1>/dev/null"
    return nil
  end

  def create_rrd_for_process(rrd_file)
    rrd = RRD::Base.new(rrd_file)
    unless File.exist? rrd_file
      puts "Creating rrd database: #{rrd_file}"
      rrd.create start: Time.now - 10.seconds, step: 30.seconds do
        datasource "memory", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
        datasource "cpu", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
        archive :average, every: 1.minutes, during: 1.year
      end
    end
    return rrd
  end

  # Collect pid files
  while
    servers = Dir[@pid_path.join("server*")].collect { |f| extract_pid(f) }
    delayed_jobs =  Dir[@pid_path.join("delayed_job*")].collect { |f| extract_pid(f) }
    background_jobs = Dir[@pid_path.join("background_jobs*")].collect { |f| extract_pid(f) }

    servers.each_with_index do |pid, i|
      rrd_file = @rrd_path.join("server_#{i}.rrd").to_s
      rrd = create_rrd_for_process rrd_file
      rrd.update Time.now, *get_process_stats(pid)
    end

    delayed_jobs.each_with_index do |pid, i|
      rrd_file = @rrd_path.join("delayed_job_#{i}.rrd").to_s
      rrd = create_rrd_for_process rrd_file
      rrd.update Time.now, *get_process_stats(pid)
    end

    background_jobs.each_with_index do |pid, i|
      rrd_file = @rrd_path.join("background_job_#{i}.rrd").to_s
      rrd = create_rrd_for_process rrd_file
      rrd.update Time.now, *get_process_stats(pid)
    end

    sleep(30)
  end
end
