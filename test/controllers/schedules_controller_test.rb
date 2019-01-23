# frozen_string_literal: true

require "test_helper"

class SchedulesControllerTest < ActionController::TestCase
  def setup
    @adminsession = { user_id: users(:admin).id, username: users(:admin).username }
    @create_data = {
                     schedule: {
                       name: "New test schedule"
                     }
                   }

    @update_data = {
                     id: schedules(:normal).id,
                     schedule: {
                       name: "updated myself",
                       schedule_events_attributes: [{
                         id: schedule_events(:event_1).id,
                         name: "updated event"
                       }]
                     }
                   }

    @add_event_data = {
      id: schedules(:normal).id,
      schedule: {
        schedule_events_attributes: [{
          name: "New event",
          at: Time.now + 5.days,
          major: true
        }]
      }
    }

    # We don't want to generate slides into the normal place
    Slide.send(:remove_const, :FilePath)
    Slide.const_set(:FilePath, Rails.root.join("tmp", "test"))
  end

  def teardown
    # Clean up all created slides
    Slide.all.each do |s|
      clear_slide_files(s)
    end
  end

  test "get index" do
    get :index, nil, @adminsession

    assert_response :success
  end

  test "get show info" do
    [:empty, :normal].each do |s|
      get :show, { id: schedules(s).id }, @adminsession

      assert_response :success, "Error getting show for schedule: #{s}"
    end
  end

  test "get edit form" do
    [:empty, :normal].each do |s|
      get :edit, { id: schedules(s).id }, @adminsession

      assert_response :success
    end
  end

  test "get new schedule form" do
    get :new, nil, @adminsession

    assert_response :success
  end

  test "create new schedule" do
    assert_difference "MasterGroup.count", 2, "Failed to create groups for schedule" do
      assert_difference "Schedule.count", 1, "Failed to create schedule" do
        post :create, @create_data, @adminsession
      end
    end

    assert_redirected_to schedule_path(assigns(:schedule))
  end

  test "update schedule" do
    put :update, @update_data, @adminsession

    assert_redirected_to schedule_path(assigns(:schedule))
    assert_equal "updated myself", assigns(:schedule).name
    assert_equal "updated event",  assigns(:schedule).schedule_events.find(1).name
  end

  test "Add event to schedule" do
    assert_difference "schedules(:normal).schedule_events.count" do
      post :update, @add_event_data, @adminsession
    end

    assert_redirected_to schedule_path(assigns(:schedule))
    assert_equal "New event", assigns(:schedule).schedule_events.last!.name
  end

  test "Add event to schedule via xhr" do
    data = @add_event_data
    data[:format] = :js

    assert_difference "schedules(:normal).schedule_events.count" do
      post :update, data, @adminsession
    end

    assert_equal "New event", assigns(:schedule).schedule_events.last!.name
  end

  test "Delete event from schedule" do
    data = {
      id: schedules(:normal).id,
      schedule: {
        schedule_events_attributes: [{
          id: schedule_events(:event_2).id,
          _destroy: true
        }]
      }
    }
    assert_difference "schedules(:normal).schedule_events.count", -1 do
      post :update, data, @adminsession
    end

    assert_redirected_to schedule_path(assigns(:schedule))
  end
end
