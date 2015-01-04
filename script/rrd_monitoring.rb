#!/usr/bin/env ruby

# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

# This script collects some ISK statistics in rrd databases

require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'colorize'
require 'rrd'

def get_memory_usage(pid)
	`ps -o rss= -p #{pid}`.to_i # in kilobytes 
end

def extract_pid(f)
	pid = File.read(@pid_path.join(f).to_s).to_i
	
	# Check if the pid is running
	if system "ps -p #{pid} &>/dev/null"
		return pid
	else
		return nil
	end
end

# Collect pid files
@pid_path = Pathname.new File.expand_path('../../tmp/pids', __FILE__)

servers = Dir[@pid_path.join('server*')].collect {|f| extract_pid(f)}
delayed_jobs =  Dir[@pid_path.join('delayed_job*')].collect {|f| extract_pid(f)}
background_jobs = Dir[@pid_path.join('background_jobs*')].collect {|f| extract_pid(f)}

servers.each_with_index do |s, i|
	puts "Server \##{i} pid: #{s} -> Mem: #{get_memory_usage(s)} kb"
end

delayed_jobs.each_with_index do |s, i|
	puts "Delayed_job worker \##{i} pid: #{s} -> Mem: #{get_memory_usage(s)}kb"
end

background_jobs.each_with_index do |s, i|
	puts "Backgroun_job worker \##{i} pid: #{s} -> Mem: #{get_memory_usage(s)}kb"
end


# Create rrd databases if needed
puts 'Creating rrd databases if needed...'



