# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class ScheduleEvent < ActiveRecord::Base
  belongs_to :schedule

  validates :at, :name, presence: true
  validates :major, :rescheduled, :cancelled, inclusion: { in: [true, false] }
  validates :linecount,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :schedule, presence: true

  before_validation do |event|
    if event.name.length > schedule.settings[:events][:line_length]
      new_name = String.new
      line = String.new
      event.name.split.each do |word|
        if line.length + word.length > schedule.settings[:events][:line_length]
          new_name << line << "\n"
          line = String.new
        end
        line << word + " "
      end
      new_name << line
      self.name = new_name
      self.linecount = name.split("\n").size
    end

    true
  end
end
