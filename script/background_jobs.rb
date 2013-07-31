#ISK server background jobs
require 'rubygems'
require 'daemon'
require 'net/http'

puts 'Starting ISK server background process'

#Daemon.daemonize(Rails.root.join('tmp','pids','background_jobs.pid'),Rails.root.join('log', 'background_jobs.log'))

puts Time.now.to_s + " Daemon started"

ActiveRecord::Base.connection.reconnect!
loop do
	HttpSlide.all.each do |slide|
		slide.delay.fetch!
	end
	Schedule.all.each do |schedule|
		schedule.generate_slides
	end

	#Import assemblytv schedule
	Schedule.where(:name => 'AssemblyTV').each do |schedule|
		xml = REXML::Document.new(Net::HTTP.get(URI.parse('http://elaine.aketzu.net/channels/9/playlist/schedule.xml')))
		xml.root.elements.each('//entry') do |entry|
			event = schedule.schedule_events.where(:external_id => entry.attributes['id']).first_or_initialize
			event.name = entry.elements.to_a('title[@lang="en"]').first.text
			event.at = Time.parse(entry.elements.to_a('start_at').first.text)
			event.save!
		end
		
		#Remove cancelled programs
		schedule.schedule_events.each do |event|
			event.delete if xml.root.elements.to_a('entry[@id="'+event.external_id+'"]').blank?
		end
		
		schedule.delay.generate_slides
		
	end
	
	#Fetch barro-schedule and update schedules based on it
	Schedule.where(:name => 'Major events').each do |schedule|
		barro_data = Net::HTTP.get(URI.parse('http://schedule.assembly.org/asms13/schedules/events.json'))
		json = JSON.parse(barro_data)
		json["events"].each do |entry|
			if entry['flags'].include?('major') or entry['flags'].include?('bigscreen')
				event = schedule.schedule_events.where(:external_id => entry['key']).first_or_initialize
				event.name = entry['name']
				event.at = Time.parse(entry['start_time'])
				event.save!
				event.delete if entry['flags'].include?('cancelled')
			end
		end
		
		schedule.delay.generate_slides
		
		
		
	end
	
	
	
	sleep(60)
end
