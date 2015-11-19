# ISK - A web controllable slideshow system
#
# Helpers and mock-ups to test tubesock endpoints.
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

module TestTubesock
	
	# Class to yield after the controller hijacks the connection
	class TestSocket
		@open_handlers		= []
		@message_handlers = []
		@close_handlers		= []
		@error_handlers		= []
		
		def initialize(message, data)
			@message = message
			@open_handlers		= []
			@message_handlers = []
			@close_handlers		= []
			@error_handlers		= []
			@data_sent = []
			@closed = false
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
		
		def data_sent
			@data_sent
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
			@message_handlers.each do |h|
				begin
					h.call(@message)
				rescue => e
					@error_handlers.each{|eh| eh.call(e,data)}
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
			socket = TestSocket.new(@_tubesock_message, @_tubesock_output)
			yield socket
			socket.run
			@_tubesock_output = socket.data_sent
			render text: nil, status: -1
		end
	end
	
	# Methods for easier testing
	module TestHelpers
		def tube(action, params, session, message)
			unless @controller.respond_to? :tubesock_output
				@controller.extend(TestTubesock::ControllerExtensions)
			end
			@controller.tubesock_message = message
			get action, params, session
		end
		
		def tubesock_output
			@controller.tubesock_output
		end
	end
end