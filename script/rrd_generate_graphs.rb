#!/usr/bin/env ruby
# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

# This script will generate graphs from rrd databases

require "rubygems"

# Set up gems listed in the Gemfile.
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)
require "bundler/setup" if File.exist?(ENV["BUNDLE_GEMFILE"])

require "colorize"
require "rrd"
require_relative "../lib/rrd_helpers.rb"

@rrd_path = Pathname.new File.expand_path("../../data/rrd", __FILE__)

graph_options = {
  width: 800,
  height: 250,
  color: ["FONT#000000", "BACK#FFFFFF"],
  font: [
    "LEGEND:8:DejaVuSansMono,DejaVu Sans Mono,DejaVu LGC Sans Mono,Bitstream Vera Sans Mono,monospace"
  ],
  start: Time.now - 2.days,
  end: Time.now
}

process_stats = Hash.new
process_stats["server"] = Dir[@rrd_path.join("server_*.rrd")].collect { |f| @rrd_path.join(f) }
process_stats["delayed_job"] = Dir[@rrd_path.join("resque_*.rrd")].collect { |f| @rrd_path.join(f) }
process_stats["background_job"] = Dir[@rrd_path.join("background_job_*.rrd")].collect { |f| @rrd_path.join(f) }
wpe = Dir[@rrd_path.join("wpe_*.rrd")].collect { |f| @rrd_path.join(f) }

# Generate graph about memory usage
RRD.graph! @rrd_path.join("memory.png").to_s, { title: "Memory usage" }.merge(graph_options) do
  process_stats.each_pair do |k, v|
    v.each_with_index do |file, i|
      value = "mem_#{k}_#{i}"
      for_rrd_data value, memory: :average, from: file
      draw_line data: value, color: color, label: "#{k} \##{i}".ljust(25), width: 1
      print_value value, format: 'LAST:Current\:%8.2lf %s'
      print_value value, format: 'AVERAGE:Average\:%8.2lf %s'
      print_value value, format: 'MAX:Maximum\:%8.2lf %s\n'
    end
  end
end

# Generate graph about CPU usage
RRD.graph! @rrd_path.join("cpu.png").to_s, { title: "CPU usage" }.merge(graph_options) do
  process_stats.each_pair do |k, v|
    v.each_with_index do |file, i|
      value = "cpu_#{k}_#{i}"
      for_rrd_data value, cpu: :average, from: file
      draw_line data: value, color: color, label: "#{k} \##{i}".ljust(25), width: 1
      print_value value, format: 'LAST:Current\: %2.2lf%%'
      print_value value, format: 'AVERAGE:Average\: %2.2lf%%'
      print_value value, format: 'MAX:Maximum\: %2.2lf%%\n'
    end
  end
end

RRD.graph! @rrd_path.join("rpi_mem.png").to_s, { title: "RPI free memory" }.merge(graph_options) do
  wpe.each do |file|
    # extract the id
    i = file.to_s.match(/wpe_(\d+).rrd/).captures.first

    value = "rpi_memfree_#{i}"
    for_rrd_data value, free: :average, from: file
    draw_line data: value, color: color, label: "WPE \##{i}".ljust(25), width: 1
    print_value value, format: 'LAST:Current\:%8.2lf %s'
    print_value value, format: 'AVERAGE:Average\:%8.2lf %s'
    print_value value, format: 'MIN:Minimum\:%8.2lf %s\n'
  end
end

RRD.graph! @rrd_path.join("rpi_temp.png").to_s, { title: "RPI temperature" }.merge(graph_options) do
  wpe.each do |file|
    # extract the id
    i = file.to_s.match(/wpe_(\d+).rrd/).captures.first

    value = "rpi_temp_#{i}"
    for_rrd_data value, temp: :average, from: file

    draw_line data: value, color: color, label: "RPI #{i} temperature".ljust(25), width: 1
    print_value value, format: 'LAST:Current\: %2.2lfC'
    print_value value, format: 'AVERAGE:Average\: %2.2lfC'
    print_value value, format: 'MAX:Maximum\: %2.2lfC\n'
  end
end

#
# # TODO: use the old code for more detailed graphs
# RRD.graph! "rpi_memstat_#{g.first}.png", title: "RPI memory (#{g.first})", width: 800, height: 250, start: g.last, end: Time.now do
#   for_rrd_data "free", free: :average, from: rrd_file
#   for_rrd_data "active", active: :average, from: rrd_file
#   for_rrd_data "inactive", inactive: :average, from: rrd_file
#
#   draw_line data: "free", :color => '#00FF00', :label => "Free", :width => 1
#   print_value "free:LAST", :format => 'Current\: %6.2lf %S'
#   print_value "free:AVERAGE", :format => 'Average\: %6.2lf %S'
#   print_value "free:MIN", :format => 'Min\: %6.2lf %S'
#   print_value "free:MAX", :format => 'Max\: %6.2lf %S\n'
#
#   draw_line data: "active", :color => '#0000FF', :label => "Active", :width => 1
#   print_value "active:LAST", :format => 'Current\: %6.2lf %S'
#   print_value "active:AVERAGE", :format => 'Average\: %6.2lf %S'
#   print_value "active:MIN", :format => 'Min\: %6.2lf %S'
#   print_value "active:MAX", :format => 'Max\: %6.2lf %S\n'
#
#   draw_line data: "inactive", :color => '#FF0000', :label => "Inactive", :width => 1
#   print_value "inactive:LAST", :format => 'Current\: %6.2lf %S'
#   print_value "inactive:AVERAGE", :format => 'Average\: %6.2lf %S'
#   print_value "inactive:MIN", :format => 'Min\: %6.2lf %S'
#   print_value "inactive:MAX", :format => 'Max\: %6.2lf %S\n'
# end
#
# RRD.graph! "rpi_wpe_#{g.first}.png", title: "WPE memory (#{g.first})", width: 800, height: 250, start: g.last, end: Time.now do
#   for_rrd_data "web_vsz", web_vsz: :average, from: rrd_file
#   for_rrd_data "web_rss", web_rss: :average, from: rrd_file
#   for_rrd_data "net_vsz", net_vsz: :average, from: rrd_file
#   for_rrd_data "net_rss", net_rss: :average, from: rrd_file
#
#   draw_line data: "web_vsz", :color => '#00FF00', :label => "WebProcess VSZ", :width => 1
#   print_value "web_vsz:LAST", :format => 'Current\: %6.2lf %S'
#   print_value "web_vsz:AVERAGE", :format => 'Average\: %6.2lf %S'
#   print_value "web_vsz:MIN", :format => 'Min\: %6.2lf %S'
#   print_value "web_vsz:MAX", :format => 'Max\: %6.2lf %S\n'
#
#   draw_line data: "web_rss", :color => '#0000FF', :label => "WebProcess RSS", :width => 1
#   print_value "web_rss:LAST", :format => 'Current\: %6.2lf %S'
#   print_value "web_rss:AVERAGE", :format => 'Average\: %6.2lf %S'
#   print_value "web_rss:MIN", :format => 'Min\: %6.2lf %S'
#   print_value "web_rss:MAX", :format => 'Max\: %6.2lf %S\n'
#
#   draw_line data: "net_vsz", :color => '#FF0000', :label => "NetworkProcess VSZ", :width => 1
#   print_value "net_vsz:LAST", :format => 'Current\: %6.2lf %S'
#   print_value "net_vsz:AVERAGE", :format => 'Average\: %6.2lf %S'
#   print_value "net_vsz:MIN", :format => 'Min\: %6.2lf %S'
#   print_value "net_vsz:MAX", :format => 'Max\: %6.2lf %S\n'
#
#   draw_line data: "net_rss", :color => '#FF00FF', :label => "NetworkProcess RSS", :width => 1
#   print_value "net_rss:LAST", :format => 'Current\: %6.2lf %S'
#   print_value "net_rss:AVERAGE", :format => 'Average\: %6.2lf %S'
#   print_value "net_rss:MIN", :format => 'Min\: %6.2lf %S'
#   print_value "net_rss:MAX", :format => 'Max\: %6.2lf %S\n'
# end
