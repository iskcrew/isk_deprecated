require "test_helper"

class ScheduleEventTest < ActiveSupport::TestCase
  test "multi line" do
    s = schedules(:normal)
    e = s.schedule_events.new
    e.name = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt..."
    e.at = Time.now
    assert e.save, "Error saving the schedule event"
    assert_equal 4, e.linecount, "Linecount wasn't as expected"
  end

  test "try to create event without time" do
    s = schedules(:normal)
    e = s.schedule_events.new
    e.name = "No time!"
    assert_not e.save, "Successfully saved a schedule event without time"
  end
end
