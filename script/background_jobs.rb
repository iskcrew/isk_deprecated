#!/usr/bin/env ruby

# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', 'environment'))

require 'net/http'

Sleep = 3.minutes # Sleep for 3 minutes between loops

def stamped_puts(str)
	puts "#{Time.now.strftime('%FT%T%z')}: " + str
end

stamped_puts 'Starting ISK server background process'
Delayed::Worker.delay_jobs = false

Daemon.daemonize(Rails.root.join('tmp','pids','background_jobs.pid'),Rails.root.join('log', 'background_jobs.log'))

stamped_puts "Daemon started"

ActiveRecord::Base.connection.reconnect!
loop do
	stamped_puts 'Fetching http-slides..'
	realtime = Benchmark.realtime do
		@slides = Event.current.slides.where(type: 'HttpSlide').all.each do |slide|
			slide.delay.fetch!
		end
	end
	stamped_puts " -> Fetched #{@slides.size} slides in %.2f seconds (%.2f sec. per slide)" % [realtime, @slides.size / realtime]
	
	stamped_puts 'Generating schedule slides..'
	realtime = Benchmark.realtime do
		@schedules = Event.current.schedules.all.each do |schedule|
			schedule.generate_slides
		end
	end
	stamped_puts(" -> Generated #{@schedules.size} schedules in %.2f seconds (%.2f sec. per schedule)" % [realtime, @schedules.size / realtime])
	
	stamped_puts "Sleeping for #{Sleep} seconds"
	sleep(Sleep)
end
