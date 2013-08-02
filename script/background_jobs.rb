#ISK server background jobs
require 'rubygems'
require 'daemon'



def stamped_puts(str)
	puts Time.now.to_s + " " + __FILE__ + ":" + __LINE__.to_s + " " + str
end

stamped_puts 'Starting ISK server background process'

#Daemon.daemonize(Rails.root.join('tmp','pids','background_jobs.pid'),Rails.root.join('log', 'background_jobs.log'))

stamped_puts Time.now.to_s + " Daemon started"

ActiveRecord::Base.connection.reconnect!
loop do
	stamped_puts 'Fetching http-slides'
	HttpSlide.all.each do |slide|
		slide.delay.fetch!
	end
	
	stamped_puts 'Generating schedule slides'
	Schedule.all.each do |schedule|
		schedule.generate_slides
	end
	sleep(60)
end
