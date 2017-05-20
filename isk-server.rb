#!/usr/bin/env ruby
# ISK - A web controllable slideshow system
#
# Script for starting and stopping all the various processes
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2015 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

require "mkmf" # We use this to check for external dependecies
require "colorize"
require "timeout"
require "redis"
require "dalli"

PidDirectory = File.join(File.dirname(__FILE__), "tmp", "pids")
Services = [
  "server",
  "resque",
  "background_jobs",
  "rrd_monitoring"
].freeze
RedisOptions = { host: "localhost", port: 6379 }.freeze
MemcachedIP = "localhost:11211".freeze
MemcachedOptions = { namespace: "ISK", compress: true }.freeze

# Check that all the needed external binaries are present
def check_deps
  puts "Checking that needed external dependencies are met..."
  unless find_executable "inkscape"
    abort "ERROR: ISK needs inkscape to function".red
  end
  # Get the inkscape version, as the new 0.91 release still has some kinks with bitmaps
  inkscape_version = `inkscape --version`.split[1]
  if inkscape_version == "0.48.5"
    abort "ERROR: Inkscape version 0.48.5 (in debian Jessie) has non-sane text element postioning, use 0.91 from jessie-backports instead".red
  end
  return if find_executable("convert") && find_executable("identify")
  abort "ERROR: ISK needs ImageMagick cmd line utilities (convert and indentify)".red
end

def start_service(process)
  case process
  when "server"
    print "Starting the web server process...".ljust(45)
    command = "bundle exec puma -C config/puma.rb > /dev/null"
  when "resque"
    print "Starting the Resque worker...".ljust(45)
    # Resque doesn't check its pid file and refuse to start if already running
    # So we need to do that...
    pid_file = File.join(PidDirectory, "resque.pid")
    if File.exist? pid_file
      pid = File.read(pid_file).to_i
      if `ps -o args -p #{pid}` =~ /resque/
        puts "FAILED".red
        puts "Resque worker already running with pid #{pid}"
        abort
      end
    end
    command = "TERM_CHILD=1 BACKGROUND=yes PIDFILE=tmp/pids/resque.pid QUEUE=* rake resque:work"
  when "background_jobs"
    print "Starting the timed background jobs worker...".ljust(45)
    command = "script/background_jobs.rb start > /dev/null"
  when "rrd_monitoring"
    print "Starting the RRD data logger process...".ljust(45)
    command = "script/rrd_monitoring.rb start > /dev/null"
  else
    abort "ERROR: Unkown process to start: #{process}".red
  end
  if system(command)
    puts "Success".green
  else
    puts "FAILED".red
    abort
  end
  return true
end

def stop_service(process)
  case process
  when "server"
    print "Stopping the web server process".ljust(45)
    pid_file = "server.pid"
  when "resque"
    print "Stopping the Resque worker".ljust(45)
    pid_file = "resque.pid"
  when "background_jobs"
    print "Stopping the timed background jobs worker".ljust(45)
    pid_file = "background_jobs.pid"
  when "rrd_monitoring"
    print "Stopping the RRD data logger process".ljust(45)
    pid_file = "rrd_monitoring.pid"
  else
    abort "ERROR: Unknown process to stop: #{process}".red
  end

  pid_file = File.join(PidDirectory, pid_file)
  unless File.exist?(pid_file)
    puts "Not running".yellow
    return true
  end
  pid = File.read(pid_file).to_i

  unless (`ps -p #{pid}`.match pid.to_s)
    puts "Not running".yellow
    return true
  end

  begin
    Process.kill("TERM", pid)
    Timeout.timeout(20) do
      begin
        print "."
        $stdout.flush
        sleep 1
      end while (`ps -p #{pid}`.match pid.to_s)
    end
    puts "Success".green
  rescue Timeout::Error
    puts "Sending SIGKILL".yellow
    Process.kill("KILL", pid)
  end
  return true
end

if ARGV[1]
  services = [ARGV[1]]
else
  services = Services
end
case ARGV[0]
when "start"
  check_deps
  services.each { |s| start_service(s) }
  exit
when "stop"
  services.each { |s| stop_service(s) }
  exit
when "restart"
  check_deps
  services.each { |s| stop_service(s) && start_service(s) }
  exit
when "force-restart"
  check_deps
  Services.each { |s| stop_service(s) }
  puts "Flushing redis databases..."
  redis = Redis.new(RedisOptions)
  redis.flushall
  puts "Flushing memcached"
  dc = Dalli::Client.new MemcachedIP, MemcachedOptions
  dc.flush_all
  puts "Precompiling assets"
  system "rake assets:precompile"
  Services.each { |s| start_service(s) }
else
  puts "Usage          isk-server.rb {start|stop|restart} [process name]"
  puts "start:         start all or a specified process"
  puts "stop:          stop all or specified process"
  puts "restart:       restart all or specified process"
  puts "force-restart: stop all services, flush redis and memcached, regenerate assets and restart"
  puts "process name can be any of the following:"
  Services.each { |s| puts s }
  exit 1
end
