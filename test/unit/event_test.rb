require 'test_helper'

class EventTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
	
	test "Create new non-current event" do
		e = Event.new
		e.name = "New test event"
		
		c = Event.current
		
		
		assert e.save, "Error saving new event"
		assert !e.current
		assert_not_equal e, Event.current, "New event became current"
		assert_equal c, Event.current, "Current event got changed"
	end
	
	test "Create new current event" do
		e = Event.new
		
		e.name = "New current event"
		e.current = true
		
		assert e.save, "Error saving event"
		assert e.current, "Event is the current one"
		assert_equal e, Event.current, "New event isn't current one"
		
	end
	
	test "set new current event" do
		e = events(:event_1)
		
		assert !e.current, "Event shouldn't be current one"
		e.current = true
		
		assert e.save, "Error saving event"
		assert_equal e, Event.current, "Event is now current one"
	end
	
	test "update current event" do
		e = events(:event_2)
		e.name = "updated name"
		
		assert e.save, "Error saving event"
		assert_equal e, Event.current, "Event is no longger current"
		
	end
end
