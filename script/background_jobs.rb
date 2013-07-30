#ISK server background jobs
require 'rubygems'
require 'daemon'


puts 'Starting ISK server background process'

Daemon.daemonize(Rails.root.join('tmp','pids','background_jobs.pid'),Rails.root.join('log', 'background_jobs.log'))

puts Time.now.to_s + " Daemon started"

ActiveRecord::Base.connection.reconnect!
loop do
	HttpSlide.all.each do |slide|
		slide.delay.fetch!
	end
	Schedule.all.each do |schedule|
		schedule.generate_slides
	end
	sleep(60 * 5)
end
