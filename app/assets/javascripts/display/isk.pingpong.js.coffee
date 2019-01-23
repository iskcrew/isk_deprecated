@isk or= {}

timeout = null

send_ping = ->
  if timeout
    clearTimeout timeout
    timeout = setTimeout ping_timeout, 5000
    isk.remote.trigger 'ping'

recv_pong = ->
  if timeout
    clearTimeout timeout
    timeout = setTimeout send_ping, 5000

ping_timeout = ->
  if timeout
    clearTimeout timeout
    timeout = null
    isk.fsm.ping_timeout()

start = ->
  isk.remote.register object:'display', method:'pong', recv_pong
  if timeout
    clearTimeout timeout
  timeout = setTimeout send_ping, 5000

stop = ->
  isk.remote.unregister object:'display', method:'pong', recv_pong
  if timeout
    clearTimeout timeout
    timeout = null

#EXPORTS
isk.pingpong =
  start: start
  stop: stop
