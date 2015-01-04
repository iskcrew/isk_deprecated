#!/usr/bin/env ruby

# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

# This script will generate graphs from rrd databases

require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'colorize'
require 'rrd'

def get_color
	colors = [
		'#30FC30',
		'#3096FC',
		'#FFC930',
		'#FF3030',
		'#30CC30',
		'#3030CC',
		'#FFFF00',
		'#CC3030',
		'#00CC00',
		'#0066CC',
		'#FF9900',
		'#CC0000',
		'#009900',
		'#000099',
		'#CCCC00',
		'#990000'
	]
	
	if @last.nil? || @last > colors.size
		@last = 0
	else
		@last += 1
	end
	return colors[@last]
end

process_stats = Hash.new

@rrd_path = Pathname.new File.expand_path('../../data/rrd', __FILE__)

process_stats['server'] = Dir[@rrd_path.join('server_*.rrd')].collect {|f| @rrd_path.join(f)}
process_stats['delayed_job'] = Dir[@rrd_path.join('delayed_job_*.rrd')].collect {|f| @rrd_path.join(f)}
process_stats['background_job'] = Dir[@rrd_path.join('background_job_*.rrd')].collect {|f| @rrd_path.join(f)}

# Generate graph about memory usage
RRD.graph! @rrd_path.join('memory.png').to_s, :title => "Memory usage", width: 800, height: 250, color: ["FONT#000000", "BACK#FFFFFF"] do
	process_stats.each_pair do |k, v|
		v.each_with_index do |file, i|
			for_rrd_data "mem_#{k}_#{i}", memory: :average, from: file
			draw_line data: "mem_#{k}_#{i}", color: get_color, label: "#{k} \##{i}", width: 1
		end
	end
end

# Generate graph about CPU usage
RRD.graph! @rrd_path.join('cpu.png').to_s, :title => "CPU usage", width: 800, height: 250, color: ["FONT#000000", "BACK#FFFFFF"] do
	process_stats.each_pair do |k, v|
		v.each_with_index do |file, i|
			for_rrd_data "cpu_#{k}_#{i}", cpu: :average, from: file
			draw_line data: "cpu_#{k}_#{i}", color: get_color, label: "#{k} \##{i}", width: 1
		end
	end
end
