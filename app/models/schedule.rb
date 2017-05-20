# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class Schedule < ActiveRecord::Base
  # Relations:
  has_many :schedule_events, -> { order at: :asc }, dependent: :delete_all
  belongs_to :event
  belongs_to :slidegroup, class_name: "MasterGroup", dependent: :destroy
  belongs_to :next_up_group, class_name: "MasterGroup", dependent: :destroy

  # Allow updating the schedule events in one call
  accepts_nested_attributes_for :schedule_events, allow_destroy: true

  # Validations:
  # TODO: validate slidegroup etc existance
  validates :name, presence: true

  # Callbacks:
  # Create groups that will contain the slides generated from this schedule
  after_create :create_groups
  # Rename the associated groups if the schedule name changes
  after_update :rename_groups

  # Return all schedules in the current event
  def self.current
    self.where(event_id: Event.current.id)
  end

  # Settings for this schedule
  # TODO: Still allow custom per schedule settings?
  def settings
    @_settings ||= self.event.config[:schedules]
  end

  # Generate schedule slides
  # FIXME: is the transaction needed?
  # FIXME: break this into smaller methods...
  def generate_slides
    Schedule.transaction do
      # Use the schedule name if custom slide header hasn't been defined
      header = self.slide_header.present? ? self.slide_header : self.name

      # Paginate the schedule events into slides
      slide_data = paginate_events(events_array)
      total_slides = slide_data.size
      current_slide = 1

      # Slide description to use on all generated slides
      slide_description = "Automatically generated from schedule #{self.name} at #{I18n.l Time.now, format: :short}"
      # Make sure there are right amount of slides in our group
      delta = slide_data.count - schedule_slide_count
      if delta.positive?
        add_scheduleslides(slide_data.count - schedule_slide_count)
      elsif delta.negative?
        self.slidegroup.slides.where(type: ScheduleSlide.sti_name)
          .limit(-delta).each(&:destroy)
      end

      # Find the scheduleslides in our slidegroup
      schedule_slides = self.slidegroup.slides.where(type: ScheduleSlide.sti_name).to_a

      # Create a array containing a slide and the data to be shown on that slide
      # FIXME: there must be a cleaner way...
      slides = Array.new
      slide_data.each_index do |i|
        slides << [schedule_slides[i], slide_data[i]]
      end

      # Set the data to each corresponding slide
      slides.each do |s|
        if total_slides == 1
          @header = header
        else
          @header = "#{header} #{current_slide}/#{total_slides}"
        end
        slide = s.first
        slide.name = @header
        slide.description = slide_description
        self.slidegroup.slides << slide
        slide.publish
        slide.save!
        @items = s.last
        # Generate the slide SVG
        slide.create_svg(@header, @items)
        slide.generate_images_later

        current_slide += 1
      end # slides.each

      self.slidegroup.publish_slides

      # Generate the "up next" slide if needed
      if self.next_up && self.schedule_events.present?
        generate_next_up_slide
      end

    end # Transaction
    return true
  end

  def generate_slides_later
    GenerateSlidesJob.perform_later self
  end

private

  # Create the associated groups when a new schedule is created
  def create_groups
    sg = MasterGroup.create(name: ("Schedule: #{self.name} slides"), event_id: self.event_id)
    ung = MasterGroup.create(name: ("Schedule: #{self.name} next up"), event_id: self.event_id)

    self.slidegroup = sg
    self.next_up_group = ung
    unless self.event_id
      self.event_id = Event.current.id
    end
    self.save!
  end

  # Rename the groups containing our slides on update
  def rename_groups
    self.slidegroup.update_attributes(name: "Schedule: #{self.name} slides")
    self.next_up_group.update_attributes(name: "Schedule #{self.name} next up")
  end

  # Generate a slide with the next EventsPerSlide schedule events
  def generate_next_up_slide
    slide_description = "Next #{settings[:events][:per_slide]} events on schedule #{self.name}"
    slide_name = self.next_up_header.present? ? self.next_up_header : "Next up: #{self.name}"

    slides = paginate_events(events_array(false))
    slides.each do |slide|
      nus = find_or_initialize_next_up_slide
      nus.name = slide_name
      nus.description = slide_description
      @header = slide_name
      @items = slide
      nus.create_svg @header, @items
      nus.save!
      nus.generate_images_later
      break
    end
    return true
  end

  # Find or create the slide for "next up" slide
  def find_or_initialize_next_up_slide
    if self.next_up_group.slides.where(type: ScheduleSlide.sti_name).first.present?
      return self.next_up_group.slides.where(type: ScheduleSlide.sti_name).first!
    end
    slide = ScheduleSlide.new
    self.next_up_group.slides << slide
    return slide
  end

  # Convenience method for getting the count of schedule slides in our slidegroup
  def schedule_slide_count
    self.slidegroup.slides.where(type: ScheduleSlide.sti_name).count
  end

  # Add more schedule slides to our slidegroup up to 'number' slides
  def add_scheduleslides(number)
    slide_description = "Automatically generated from schedule #{self.name} at #{I18n.l Time.now, format: :short}"
    number.times do
      slide = ScheduleSlide.new
      slide.name = self.name
      slide.description = slide_description
      self.slidegroup.slides << slide
      slide.save!
    end
  end

  # Form a array of schedule events and inser subheaders for date changes if needed
  def events_array(do_subheaders = true)
    slide_items = Array.new
    last_date = nil

    self.schedule_events.each do |e|
      # Ignore events that are more than settings[:time_tolerance] in past
      unless (e.at + settings[:time_tolerance]).past?
        # Insert a subheader if next event is in different day
        if do_subheaders && !(e.at.to_date === last_date)
          slide_items << { subheader: (e.at.strftime("%A %d.%m.")), linecount: 1 }
        end
        slide_items << { name: e.name, time: e.at.strftime("%H:%M"), linecount: e.linecount }
        last_date = e.at.to_date
      end
    end
    return slide_items
  end

  # Create an array containing items for each slide suitable for the template
  # A slide contains at most EventsPerSlide number of events in it
  # If day changes between slides a new header will be added
  # If the new day would have less than self.min_events_on_next_day events after it on the current slide
  # create a new slide.
  def paginate_events(slide_items)
    # Break the events up on slides EventsPerSlide per slide
    slides = Array.new
    this_slide = Array.new
    last_subheader = nil

    slide_items.each do |item|
      if item[:subheader]
        if (this_slide.size + self.min_events_on_next_day > settings[:events][:per_slide])
          slides << this_slide
          this_slide = Array.new
        end
        last_subheader = item
      elsif this_slide.empty? && last_subheader
        this_slide << last_subheader
      end

      if item[:linecount] == 1
        this_slide << item
      else
        if (this_slide.size + item[:linecount]) > settings[:events][:per_slide]
          if this_slide.last[:subheader]
            this_slide.pop
          end
          slides << this_slide
          this_slide = Array.new
          this_slide << last_subheader
        end
        lines = item[:name].split("\n")
        this_slide << { name: lines.first, time: item[:time] }
        lines.delete_at 0
        (item[:linecount] - 1).times do
          this_slide << { name: lines.first, time: "" }
          lines.delete_at 0
        end
      end

      if this_slide.size >= settings[:events][:per_slide]
        slides << this_slide
        this_slide = Array.new
      end
    end

    slides << this_slide unless this_slide.empty?
    return slides
  end
end
