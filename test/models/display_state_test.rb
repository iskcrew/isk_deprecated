# frozen_string_literal: true
require "test_helper"

class DisplayStateTest < ActiveSupport::TestCase
  test "ipv6 address" do
    ds = DisplayState.new
    ds.monitor = false
    ds.status = "disconnected"
    ds.ip = "ABCD:ABCD:ABCD:ABCD:ABCD:ABCD:ABCD:ABCD"
    assert ds.save, "Error saving DisplayState with ipv6 address."

    ds.ip = "ABCD:ABCD:ABCD:ABCD:ABCD:ABCD:192.168.158.190"
    assert ds.save, "Error saving DisplayState with ipv4 mapped ipv6 address"
  end
end
