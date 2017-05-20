# frozen_string_literal: true
require "test_helper"

class EventsControllerTest < ActionController::TestCase
  def setup
    @adminsession = { user_id: users(:admin).id, username: users(:admin).username }
  end

  test "get index" do
    get :index, nil, @adminsession
    assert_response :success
  end

  test "get details" do
    Event.all.each do |e|
      get :show, { id: e.id }, @adminsession
      assert_response :success
    end
  end

  test "get edit page" do
    get :edit, { id: events(:current).id }, @adminsession
    assert_response :success
  end

  test "edit event" do
    e = events(:current)
    data = {
      id: e.id,
      event: {
        name: "Changed"
      }
    }

    post :update, data, @adminsession
    assert_redirected_to event_path(e.id)
    assert e.reload
    assert e.name == "Changed"
  end

  test "post invalid update data" do
    e = events(:current)
    data = {
      id: e.id,
      event: {
        name: nil
      }
    }

    post :update, data, @adminsession
    assert_template :edit

  end

  test "get new event form" do
    get :new, nil, @adminsession
    assert_response :success
  end

  test "create new event" do
    data = {
      event: {
        name: "New event",
        current: true
      }
    }

    assert_difference "Event.count" do
      post :create, data, @adminsession
      assert_redirected_to events_path
    end
  end
end
