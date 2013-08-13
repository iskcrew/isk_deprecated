# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


require 'rubygems'
require 'daemon'
require 'net/http'


def stamped_puts(str)
	puts Time.now.to_s + caller[0] + ' ' + str
end

stamped_puts 'Starting ISK server background process'

Daemon.daemonize(Rails.root.join('tmp','pids','background_jobs.pid'),Rails.root.join('log', 'background_jobs.log'))

stamped_puts Time.now.to_s + " Daemon started"

ActiveRecord::Base.connection.reconnect!
loop do
	#Import assemblytv schedule
	Schedule.where(:name => 'AssemblyTV').each do |schedule|
		stamped_puts 'Fetching AssemblyTV schedule'
		begin
			xml = REXML::Document.new(Net::HTTP.get(URI.parse('http://elaine.aketzu.net/channels/9/playlist/schedule.xml')))
				xml.root.elements.each('//entry') do |entry|
					event = schedule.schedule_events.where(:external_id => entry.attributes['id']).first_or_initialize
					event.name =entry.elements.to_a('title[@lang="en"]').first.text
					event.at = Time.parse(entry.elements.to_a('start_at').first.text)
					event.save!
			end
		
			#Remove cancelled programs
			schedule.schedule_events.each do |event|
				event.delete if xml.root.elements.to_a('entry[@id="'+event.external_id+'"]').blank?
			end
		
		rescue
			#HTTP timeout, retry next time
		end
	end
	
	#Fetch barro-schedule and update schedules based on it (major events)
	Schedule.where(:name => 'Major events').each do |schedule|
		stamped_puts 'Fetching Assmebly schedule, using major events'
		begin
			barro_data = Net::HTTP.get(URI.parse('http://schedule.assembly.org/asms13/schedules/events.json'))
			json = JSON.parse(barro_data)
			schedule.schedule_events.delete_all
			json["events"].each do |entry|
				if entry['flags'].include?('major') or entry['flags'].include?('bigscreen')
					event = schedule.schedule_events.where(:external_id => entry['key']).first_or_initialize
					event.name = entry['name'].strip
					event.at = Time.parse(entry['start_time'])
					event.save!
					event.delete if entry['flags'].include?('cancelled')
				end
			end
		
		rescue 
		
		end
	end
	
	#Fetch barro-schedule and update schedules based on it (seminars)
	Schedule.where(:name => 'ARTtech Seminars').each do |schedule|
		stamped_puts 'Fetching Assembly schedule, using seminars'
		begin
			barro_data = Net::HTTP.get(URI.parse('http://schedule.assembly.org/asms13/schedules/events.json'))
			json = JSON.parse(barro_data)
			schedule.schedule_events.delete_all
			json["events"].each do |entry|
				if entry['categories'].include?('Seminar')
					event = schedule.schedule_events.where(:external_id => entry['key']).first_or_initialize
					event.name = entry['name'].split('ARTtech seminars:').last.strip
					event.at = Time.parse(entry['start_time'])
					event.save!
					event.delete if entry['flags'].include?('cancelled')
				end
			end
		
		rescue 
		
		end
	end
	
	#Generate slides for 5 latest photos from assembly gallery
	begin
		require 'net/http'
		require 'uri'
		require 'base64'
		require 'rexml/document'

		stamped_puts 'Fetching latests assembly.galleria.fi pictures'

		rss = `wget http://assembly.galleria.fi/kuvat/rss/ -O - 2>/dev/null`
		xml = REXML::Document.new(rss)

		slides_index = 0
		slides = [300]

		xml.root.elements.each('//item') do |item|
			picture = Net::HTTP.get(URI.parse(item.elements.to_a('link').first.text + '/_full.jpg'))
			rm_picture = Magick::Image.from_blob(picture).first
	
			if ((rm_picture.columns.to_f / rm_picture.rows.to_f) - 1.5).abs < 0.01
				slide = Slide.find(slides[slides_index])
				svg = svg = REXML::Document.new(slide.svg_data)
				encoded = 'data:image/jpeg;base64,' + Base64.encode64(picture)
				picture_element = svg.root.elements.to_a('//image#gallery_picture').last
				picture_element.add_attribute('xlink:href', encoded)
		
				File.open(slide.svg_filename, 'w+') do |f|
					f.puts svg.to_s
				end
				slide.generate_images
		
				slides_index+= 1
				break if slides_index >= slides.size
			end
	
	
		end
		
		
	rescue
		
	end
	
	
	stamped_puts 'Fetching http-slides'
	HttpSlide.all.each do |slide|
		slide.delay.fetch!
	end
	
	stamped_puts 'Generating schedule slides'
	Schedule.all.each do |schedule|
		schedule.generate_slides
	end
	
	sleep(180)
end
