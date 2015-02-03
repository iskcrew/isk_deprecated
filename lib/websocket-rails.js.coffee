###
WebsocketRails JavaScript Client

Setting up the dispatcher:
  var dispatcher = new WebSocketRails('localhost:3000/websocket');
  dispatcher.on_open = function() {
    // trigger a server event immediately after opening connection
    dispatcher.trigger('new_user',{user_name: 'guest'});
  })

Triggering a new event on the server
  dispatcherer.trigger('event_name',object_to_be_serialized_to_json);

Listening for new events from the server
  dispatcher.bind('event_name', function(data) {
    console.log(data.user_name);
  });

Stop listening for new events from the server
  dispatcher.unbind('event')
###
class @WebSocketRails
  constructor: (@url, @use_websockets = true) ->
    @callbacks = {}
    @channels  = {}
    @queue     = {}

    @connect()

  connect: ->
    @state = 'connecting'

    unless @supports_websockets() and @use_websockets
      @_conn = new WebSocketRails.HttpConnection @url, @
    else
      @_conn = new WebSocketRails.WebSocketConnection @url, @

    @_conn.new_message = @new_message

  disconnect: ->
    if @_conn
      @_conn.close()
      delete @_conn._conn
      delete @_conn

    @state     = 'disconnected'

  # Reconnects the whole connection, 
  # keeping the messages queue and its' connected channels.
  # 
  # After successfull connection, this will:
  # - reconnect to all channels, that were active while disconnecting
  # - resend all events from which we haven't received any response yet
  reconnect: =>
    old_connection_id = @_conn?.connection_id

    @disconnect()
    @connect()

    # Resend all unfinished events from the previous connection.
    for id, event of @queue
      if event.connection_id == old_connection_id && !event.is_result()
        @trigger_event event

    @reconnect_channels()

  new_message: (data) =>
    for socket_message in data
      event = new WebSocketRails.Event( socket_message )
      if event.is_result()
        @queue[event.id]?.run_callbacks(event.success, event.data)
        delete @queue[event.id]
      else if event.is_channel()
        @dispatch_channel event
      else if event.is_ping()
        @pong()
      else
        @dispatch event

      if @state == 'connecting' and event.name == 'client_connected'
        @connection_established event.data

  connection_established: (data) =>
    @state         = 'connected'
    @_conn.setConnectionId(data.connection_id)
    @_conn.flush_queue()
    if @on_open?
      @on_open(data)

  bind: (event_name, callback) =>
    @callbacks[event_name] ?= []
    @callbacks[event_name].push callback

  unbind: (event_name) =>
    delete @callbacks[event_name]

  trigger: (event_name, data, success_callback, failure_callback) =>
    event = new WebSocketRails.Event( [event_name, data, @_conn?.connection_id], success_callback, failure_callback )
    @trigger_event event

  trigger_event: (event) =>
    @queue[event.id] ?= event # Prevent replacing an event that has callbacks stored
    @_conn.trigger event if @_conn
    event

  dispatch: (event) =>
    return unless @callbacks[event.name]?
    for callback in @callbacks[event.name]
      callback event.data

  subscribe: (channel_name, success_callback, failure_callback) =>
    unless @channels[channel_name]?
      channel = new WebSocketRails.Channel channel_name, @, false, success_callback, failure_callback
      @channels[channel_name] = channel
      channel
    else
      @channels[channel_name]

  subscribe_private: (channel_name, success_callback, failure_callback) =>
    unless @channels[channel_name]?
      channel = new WebSocketRails.Channel channel_name, @, true, success_callback, failure_callback
      @channels[channel_name] = channel
      channel
    else
      @channels[channel_name]

  unsubscribe: (channel_name) =>
    return unless @channels[channel_name]?
    @channels[channel_name].destroy()
    delete @channels[channel_name]

  dispatch_channel: (event) =>
    return unless @channels[event.channel]?
    @channels[event.channel].dispatch event.name, event.data

  supports_websockets: =>
    (typeof(WebSocket) == "function" or typeof(WebSocket) == "object")

  pong: =>
    pong = new WebSocketRails.Event( ['websocket_rails.pong', {}, @_conn?.connection_id] )
    @_conn.trigger pong

  connection_stale: =>
    @state != 'connected'

  # Destroy and resubscribe to all existing @channels.
  reconnect_channels: ->
    for name, channel of @channels
      callbacks = channel._callbacks
      channel.destroy()
      delete @channels[name]

      channel = if channel.is_private
        @subscribe_private name
      else
        @subscribe name
      channel._callbacks = callbacks
      channel
###
The Event object stores all the relevant event information.
###

class WebSocketRails.Event

  constructor: (data, @success_callback, @failure_callback) ->
    @name    = data[0]
    attr     = data[1]
    if attr?
      @id      = if attr['id']? then attr['id'] else (((1+Math.random())*0x10000)|0)
      @channel = if attr.channel? then attr.channel
      @data    = if attr.data? then attr.data else attr
      @token   = if attr.token? then attr.token
      @connection_id = data[2]
      if attr.success?
        @result  = true
        @success = attr.success

  is_channel: ->
    @channel?

  is_result: ->
    typeof @result != 'undefined'

  is_ping: ->
    @name == 'websocket_rails.ping'

  serialize: ->
      JSON.stringify [@name, @attributes()]

  attributes: ->
    id: @id,
    channel: @channel,
    data: @data
    token: @token

  run_callbacks: (@success, @result) ->
    if @success == true
      @success_callback?(@result)
    else
      @failure_callback?(@result)
###
 Abstract Interface for the WebSocketRails client.
###
class WebSocketRails.AbstractConnection

  constructor: (url, @dispatcher) ->
    @message_queue   = []

  close: ->

  trigger: (event) ->
    if @dispatcher.state != 'connected'
      @message_queue.push event
    else
      @send_event event

  send_event: (event) ->
    # Events queued before connecting do not have the correct
    # connection_id set yet. We need to update it before dispatching.
    event.connection_id = @connection_id if @connection_id?

    # ...
    
  on_close: (event) ->
    if @dispatcher && @dispatcher._conn == @
      close_event = new WebSocketRails.Event(['connection_closed', event])
      @dispatcher.state = 'disconnected'
      @dispatcher.dispatch close_event

  on_error: (event) ->
    if @dispatcher && @dispatcher._conn == @
      error_event = new WebSocketRails.Event(['connection_error', event])
      @dispatcher.state = 'disconnected'
      @dispatcher.dispatch error_event

  on_message: (event_data) ->
    if @dispatcher && @dispatcher._conn == @
      @dispatcher.new_message event_data

  setConnectionId: (@connection_id) ->

  flush_queue: ->
    for event in @message_queue
      @trigger event
    @message_queue = []
###
 HTTP Interface for the WebSocketRails client.
###
class WebSocketRails.HttpConnection extends WebSocketRails.AbstractConnection
  connection_type: 'http'

  _httpFactories: -> [
    -> new XDomainRequest(),
    -> new XMLHttpRequest(),
    -> new ActiveXObject("Msxml2.XMLHTTP"),
    -> new ActiveXObject("Msxml3.XMLHTTP"),
    -> new ActiveXObject("Microsoft.XMLHTTP")
  ]

  constructor: (url, @dispatcher) ->
    super
    @_url          = "http://#{url}"
    @_conn         = @_createXMLHttpObject()
    @last_pos      = 0
    try
      @_conn.onreadystatechange = => @_parse_stream()
      @_conn.addEventListener("load", @on_close, false)
    catch e
      @_conn.onprogress = => @_parse_stream()
      @_conn.onload = @on_close
      # set this as 3 always for parse_stream as the object does not have this property at all
      @_conn.readyState = 3
    @_conn.open "GET", @_url, true
    @_conn.send()

  close: ->
    @_conn.abort()

  send_event: (event) ->
    super
    @_post_data event.serialize()

  _post_data: (payload) ->
    $.ajax @_url,
      type: 'POST'
      data:
        client_id: @connection_id
        data: payload
      success: ->

  _createXMLHttpObject: ->
    xmlhttp   = false
    factories = @_httpFactories()
    for factory in factories
      try
        xmlhttp = factory()
      catch e
        continue
      break
    xmlhttp

  _parse_stream: ->
    if @_conn.readyState == 3
      data         = @_conn.responseText.substring @last_pos
      @last_pos    = @_conn.responseText.length
      data = data.replace( /\]\]\[\[/g, "],[" )
      try
        event_data = JSON.parse data
        @on_message(event_data)
      catch e
        # just ignore if it cannot be parsed, probably whitespace
###
WebSocket Interface for the WebSocketRails client.
###
class WebSocketRails.WebSocketConnection extends WebSocketRails.AbstractConnection
  connection_type: 'websocket'
  
  constructor: (@url, @dispatcher) ->
    super
    if @url.match(/^wss?:\/\//)
        console.log "WARNING: Using connection urls with protocol specified is depricated"
    else if window.location.protocol == 'https:'
        @url             = "wss://#{@url}"
    else
        @url             = "ws://#{@url}"
    @_conn           = new WebSocket(@url)
    @_conn.onmessage = (event) => 
      event_data = JSON.parse event.data
      @on_message(event_data)
    @_conn.onclose   = (event) => 
      @on_close(event)
    @_conn.onerror   = (event) => 
      @on_error(event)

  close: ->
    @_conn.close()

  send_event: (event) ->
    super
    @_conn.send event.serialize()
###
The channel object is returned when you subscribe to a channel.

For instance:
  var dispatcher = new WebSocketRails('localhost:3000/websocket');
  var awesome_channel = dispatcher.subscribe('awesome_channel');
  awesome_channel.bind('event', function(data) { console.log('channel event!'); });
  awesome_channel.trigger('awesome_event', awesome_object);

If you want to unbind an event, you can use the unbind function :
  awesome_channel.unbind('event')
###
class WebSocketRails.Channel

  constructor: (@name, @_dispatcher, @is_private = false, @on_success, @on_failure) ->
    @_callbacks = {}
    @_token = undefined
    @_queue = []
    if @is_private
      event_name = 'websocket_rails.subscribe_private'
    else
      event_name = 'websocket_rails.subscribe'

    @connection_id = @_dispatcher._conn?.connection_id
    event = new WebSocketRails.Event( [event_name, {data: {channel: @name}}, @connection_id], @_success_launcher, @_failure_launcher)
    @_dispatcher.trigger_event event

  destroy: ->
    if @connection_id == @_dispatcher._conn?.connection_id
      event_name = 'websocket_rails.unsubscribe'
      event =  new WebSocketRails.Event( [event_name, {data: {channel: @name}}, @connection_id] )
      @_dispatcher.trigger_event event
    @_callbacks = {}

  bind: (event_name, callback) ->
    @_callbacks[event_name] ?= []
    @_callbacks[event_name].push callback

  unbind: (event_name) ->
    delete @_callbacks[event_name]

  trigger: (event_name, message) ->
    event = new WebSocketRails.Event( [event_name, {channel: @name, data: message, token: @_token}, @connection_id] )
    if !@_token
      @_queue.push event
    else
      @_dispatcher.trigger_event event

  dispatch: (event_name, message) ->
    if event_name == 'websocket_rails.channel_token'
      @connection_id = @_dispatcher._conn?.connection_id
      @_token = message['token']
      @flush_queue()
    else
      return unless @_callbacks[event_name]?
      for callback in @_callbacks[event_name]
        callback message

  # using this method because @on_success will not be defined when the constructor is executed
  _success_launcher: (data) =>
    @on_success(data) if @on_success?

  # using this method because @on_failure will not be defined when the constructor is executed
  _failure_launcher: (data) =>
    @on_failure(data) if @on_failure?

  flush_queue: ->
    for event in @_queue
      @_dispatcher.trigger_event event
    @_queue = []
