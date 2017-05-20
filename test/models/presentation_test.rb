# frozen_string_literal: true
require "test_helper"
require "redis_test_helpers"

class PresentationTest < ActiveSupport::TestCase
  include RedisTestHelpers

  test "create presentation" do
    p = Presentation.new
    p.name = "Test presentation"
    assert p.save, "Error saving presentation"
    p.reload
    assert_equal Event.current.id, p.event.id, "Presentation is not in current event"
  end

  test "slide count" do
    p = presentations(:empty)
    assert_equal 0, p.groups.count
    assert_equal 0, p.total_slides, "This presentation should be empty"
    assert_equal 0, p.public_slides.count

    p = presentations(:with_slides)

    assert_equal 4, p.groups.count
    assert_equal 13, p.total_slides
    assert_equal 13, p.public_slides.count

    p = presentations(:with_empty_group)

    assert_equal 1, p.groups.count
    assert_equal 0, p.total_slides
    assert_equal 0, p.public_slides.count

    p = presentations(:with_hidden_slides)

    assert_equal 2, p.groups.count
    assert_equal 2, p.total_slides
    assert_equal 2, p.public_slides.count
  end

  test "slide order" do
    p = presentations(:with_slides)
    slides = p.public_slides.to_a

    assert_equal slides(:slide_1), slides[0]
    assert_equal slides(:slide_11), slides[1]
    assert_equal slides(:slide_5), slides[5]
    assert_equal slides(:slide_1), slides[11]
    assert_equal slides(:not_ready), slides[12]
  end

  test "duration" do
    assert_equal 0, presentations(:empty).duration
    assert_equal 13 * 20, presentations(:with_slides).duration
    assert_equal 10 * 50 + 10, presentations(:with_special_duration).duration
  end

  test "to_hash" do
    p = presentations(:with_slides)
    h = p.to_hash

    assert_equal h[:name], p.name, "Wrong presentation name"
    assert_equal h[:slides].size, p.public_slides.count, "Wrong number of slides in hash: #{p.public_slides.count} slides in presentation, #{h[:slides].size} in hash"
  end

  test "timestamps on group update" do
    presentation = presentations(:with_slides)
    assert_not_in_delta Time.now.to_i, presentation.updated_at.to_i, 2, "Timestamp wasn't in the past at the start of test"

    # Move the last group to first
    g = presentation.groups.last
    g.position_position = 1
    g.save!
    presentation.reload
    assert_in_delta Time.now.to_i, presentation.updated_at.to_i, 2, "Timestamp didn't update"
  end

  test "timestamp on master_group update" do
    presentation = presentations(:with_slides)
    assert_not_in_delta Time.now.to_i, presentation.updated_at.to_i, 2, "Timestamp wasn't in the past at the start of test"

    # change the name of a master group
    mg = presentation.master_groups.last
    mg.name = "updating this group"
    mg.save!

    presentation.reload
    assert_in_delta Time.now.to_i, presentation.updated_at.to_i, 2, "Timestamp didn't update"
  end

  test "timestamp on slide update" do
    presentation = presentations(:with_slides)
    assert_not_in_delta Time.now.to_i, presentation.updated_at.to_i, 2, "Timestamp wasn't in the past at the start of test"

    # hide the first slide
    s = presentation.slides.first
    s.public = false
    s.save!

    presentation.reload
    assert_in_delta Time.now.to_i, presentation.updated_at.to_i, 2, "Timestamp didn't update"
  end

  test "delete presentation" do
    p = presentations(:with_slides)
    assert p.groups.present?
    assert_difference "Group.count", -p.groups.count do
      assert p.destroy
    end
  end

  test "notifications to displays" do
    p = presentations(:with_slides)
    d = p.displays.sample
    with_redis(d.websocket_channel) do
      p.delay = 200
      assert p.save
    end
    assert_one_isk_message("display", "data")
  end
end
