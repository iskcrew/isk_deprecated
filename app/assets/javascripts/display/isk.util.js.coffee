@isk or= {}

class ChangeNotifier
  constructor: (initial, callback) ->
    @state = initial
    @cb = callback
  set: (state) ->
    if @state != state
      @state = state
      @cb state
  get: () ->
    @state

# TODO remove jquery
when_ready = (elem, f) ->
  console.debug 'when_ready', elem, f
  $(elem).one 'load', f
  .each -> $(@).load() if @complete

#when_ready = (elem, cb) ->
#  elem.addEventListener 'load', f = (e) ->
#    e.target.removeEventListener(e.type, arguments.callee)
#    cb(e)
#  f.apply(elem) if elem.complete

#EXPORTS:
isk.util=
  ChangeNotifier: ChangeNotifier
  when_ready: when_ready
