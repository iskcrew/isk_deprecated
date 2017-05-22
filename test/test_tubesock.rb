# ISK - A web controllable slideshow system
#
# Helpers and mock-ups to test tubesock endpoints.
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

module TestTubesock
  # Class to yield after the controller hijacks the connection
  class TestSocket
    attr_accessor :test_error_handlers
    attr_reader :data_sent

    @open_handlers    = []
    @message_handlers = []
    @close_handlers   = []
    @error_handlers   = []

    def initialize(message, _data, error_handlers = false)
      @message = message
      @open_handlers    = []
      @message_handlers = []
      @close_handlers   = []
      @error_handlers   = []
      @data_sent = []
      @closed = false
      @test_error_handlers = error_handlers
    end

    # Register the various handlers
    def onopen(&block)
      @open_handlers << block
    end

    def onmessage(&block)
      @message_handlers << block
    end

    def onclose(&block)
      @close_handlers << block
    end

    def onerror(&block)
      @error_handlers << block
    end

    # Just store all messages that the action under test sends
    def send_data(msg)
      @data_sent << msg
    end

    # We don't have a real connection, just mark this as closed
    def close
      @closed = true
    end

    def closed?
      @closed
    end

    # Method that runs all registered callbacks
    # We start with the open_handlers, then move to message_handlers and yield the message from new()
    # If any errors are raised we pass them onto the error_handlers
    def run
      @open_handlers.each(&:call)
      return if closed?
      @message_handlers.each do |h|
        begin
          h.call(@message)
        rescue => e
          raise unless @test_error_handlers
          @error_handlers.each { |eh| eh.call(e, msg) }
        end
      end
    end
  end

  # Methods that get injected to the controller under test
  module ControllerExtensions
    # Set the message to yield to message_handlers
    def tubesock_message=(msg)
      @_tubesock_message = msg
    end

    # Get a array of any messages that were sent with tubesock.send_data
    def tubesock_output
      @_tubesock_output
    end

    # Instead of hijacking the rack connection just simulate it
    # We yield a TestSocket instance and then just run all registered callbacks.
    def hijack
      socket = TestSocket.new(@_tubesock_message, @_tubesock_output, @_tubesock_test_error_handlers)
      yield socket
      socket.run
      @_tubesock_output = socket.data_sent
      render text: nil, status: -1
    end

    # Boolean to control if the tubesock handler should rescue exceptions and run error handlers.
    # If false any exceptions are just re-raised.
    def tubesock_test_error_handlers=(value)
      @_tubesock_test_error_handlers = value
    end
  end

  # Methods for easier testing
  module TestHelpers
    def tube(action, params, session, message, test_error_handlers = false)
      unless @controller.respond_to? :tubesock_output
        @controller.extend(TestTubesock::ControllerExtensions)
      end
      @controller.tubesock_message = message
      @controller.tubesock_test_error_handlers = test_error_handlers
      get action, params, session
    end

    def tubesock_output
      @controller.tubesock_output
    end

    def assert_one_sent_message(object, type)
      assert_equal 1, tubesock_output.count, "Should have replied with one message"
      assert msg = IskMessage.from_json(tubesock_output.first), "Message should be in proper format"
      assert_equal object, msg.object, "Message should be about #{object}"
      assert_equal type, msg.type, "Message type should be #{type}"
      return msg
    end
  end
end
