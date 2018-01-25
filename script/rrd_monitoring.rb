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

  def create_rrd_for_wpe(rrd_file)
    rrd = RRD::Base.new(rrd_file)
    unless File.exist? rrd_file
      puts "Creating rrd database: #{rrd_file}"
      rrd.create start: Time.now - 10.seconds, step: 30.seconds do
        datasource "free", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
        datasource "active", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
        datasource "inactive", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
        datasource "web_vsz", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
        datasource "web_rss", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
        datasource "net_vsz", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
        datasource "net_rss", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited
        datasource "temp", type: :gauge, heartbeat: 10.minutes, min: 0, max: :unlimited

        archive :average, every: 30.seconds, during: 1.day
        archive :average, every: 2.minutes, during: 1.year
      end
    end
    return rrd
  end

  def collect_wpe_stats(display, rrd)
    # config/wpe_key
    unless File.exist? @wpe_key
      puts "No WPE key"
      return nil
    end

    Net::SSH.start(display.ip, "root", keys: [@wpe_key], verify_host_key: false, keys_only: true, timeout: 10, non_interactive: true) do |ssh|
      meminfo = +""
      ssh.exec!("cat /proc/meminfo") do |_channel, stream, data|
        meminfo << data if stream == :stdout
      end

      ps = +""
      ssh.exec!("ps -o vsz,rss,args") do |_channel, stream, data|
        ps << data if stream == :stdout
      end

      data = Hash.new
      ps.each_line do |l|
        parts = l.split
        data[parts[2]] = [parts[0], parts[1]]
      end

      meminfo.each_line do |l|
        parts = l.split
        data[parts[0]] = parts[1]
      end

      wpe = [[0, 0], [0, 0]]

      wpe[0] = data["/usr/bin/WPEWebProcess"] if data.key? "/usr/bin/WPEWebProcess"

      wpe[1] = data["/usr/bin/WPENetworkProcess"] if data.key? "/usr/bin/WPENetworkProcess"

      wpe.each_index do |i|
        wpe[i].each_index do |j|
          wpe[i][j] = wpe[i][j].to_i * 1024 if wpe[i][j][-1] == "m"
          wpe[i][j] = wpe[i][j].to_i * 1024
        end
      end

      temp = 0.0
      ssh.exec!("cat /sys/class/thermal/thermal_zone0/temp") do |_channel, _stream, t|
        temp = t.to_i / 1000.0
      end

      rrd.update! Time.now, data["MemFree:"].to_i * 1024, data["Active:"].to_i * 1024, data["Inactive:"].to_i * 1024, *wpe, temp
    end
  rescue IOError, Net::SSH::AuthenticationFailed
    puts "Error collecting WPE stats for: #{display.name}"
  end

  # Collect pid files
  loop do
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

    # Monitor WPE displays
    Display.where(wpe: true).each do |d|
      rrd_file = @rrd_path.join("wpe_#{d.id}.rrd").to_s
      rrd = create_rrd_for_wpe rrd_file
      collect_wpe_stats(d, rrd)
    end

    sleep(30)
  end
end
