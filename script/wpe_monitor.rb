#!/usr/bin/env ruby
# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md
require File.expand_path(File.join(File.dirname(__FILE__), "..", "config", "environment"))
require_relative "../lib/cli_helpers.rb"

def monitor_wpe(ip, key, name)
  Net::SSH.start(ip, "root", keys: [key], verify_host_key: false, keys_only: true) do |ssh|
    loop do
      meminfo = String.new
      ssh.exec!("cat /proc/meminfo") do |_channel, stream, data|
        meminfo << data if stream == :stdout
      end

      ps = String.new
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

      if data.key? "/usr/bin/WPEWebProcess"
        wpe[0] = data["/usr/bin/WPEWebProcess"]
      end

      if data.key? "/usr/bin/WPENetworkProcess"
        wpe[1] = data["/usr/bin/WPENetworkProcess"]
      end

      wpe.each_index do |i|
        wpe[i].each_index do |j|
          wpe[i][j] = wpe[i][j].to_i * 1024 if wpe[i][j][-1] == "m"
          wpe[i][j] = wpe[i][j].to_i * 1024
        end
      end

      temp = 0.0
      ssh.exec!("cat /sys/class/thermal/thermal_zone0/temp") do |_channel, _stream, d|
        temp = d.to_i / 1000.0
      end

      puts "#{Time.now}: Display #{name}: #{data['MemFree:'].to_i / 1024}Mb free, WPEWebProcess: RSS #{wpe.first.last / (1024 * 1024)}Mb Temp: #{temp}°C"
      sleep(30)
    end
  end
rescue IOError
  puts "\t Name: disconnected, trying to reconnect in 30s"
  sleep(30.seconds)
  retry
end

def validate_wpe(ip, key)
  Net::SSH.start(ip, "root", keys: [key], verify_host_key: false, timeout: 10, keys_only: true) do |_ssh|
    return true
  end
rescue
  return false
end

key = ARGV.last

threads = []
wpe = []
Display.all.each do |d|
  next unless d.ip.present?
  next unless d.wpe
  puts "Checking display #{d.name} IP:#{d.ip}"
  if validate_wpe(d.ip, key)
    puts"\tWPE display"
    wpe << d
  end
end

wpe.each do |d|
  threads << Thread.new { monitor_wpe(d.ip, key, d.name) }
end

threads.each(&:join)
