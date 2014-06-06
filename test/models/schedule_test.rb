require 'test_helper'

class ScheduleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
	
	test "create new schedule" do
		s = Schedule.new
		s.name = 'New test schedule'
		s.up_next = true
		
		assert s.save, "Error saving new schedule"
		assert_not_nil s.slidegroup, "Schedule does not have slidegroup"
		assert_not_nil s.up_next_group, "Schedule does not have up next group"
		assert_equal s.event, Event.current, "Schedule does not have correct event"
		
	end
	
end
