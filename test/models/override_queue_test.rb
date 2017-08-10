# frozen_string_literal: true

require "test_helper"
require "redis_test_helpers"

class OverrideQueueTest < ActiveSupport::TestCase
  include RedisTestHelpers

  test "notifications on override update" do
    oq = override_queues(:override_1)
    with_redis(oq.display.websocket_channel) do
      oq.duration = 500
      oq.save!
    end
    assert_one_isk_message("display", "data")
  end

  test "notifications on override delete" do
    oq = override_queues(:override_2)
    with_redis(oq.display.websocket_channel) do
      oq.destroy
    end
    assert_one_isk_message("display", "data")
  end

  test "notifications on override creation" do
    d = displays(:normal)
    s = slides(:simple)
    oq = OverrideQueue.new
    oq.display = d
    oq.slide = s
    oq.duration = 32
    with_redis(d.websocket_channel) do
      assert oq.save
    end
    assert_one_isk_message("display", "data")
  end
end
