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
  if elem.nodeName == 'IMG'
    $(elem).one 'load', f
    .each -> $(@).load() if @complete
  else if elem.nodeName == 'VIDEO'
    if elem.readyState >= 3
      f.bind(elem)()
    else
      $(elem).one 'canplay', f

#when_ready = (elem, cb) ->
#  elem.addEventListener 'load', f = (e) ->
#    e.target.removeEventListener(e.type, arguments.callee)
#    cb(e)
#  f.apply(elem) if elem.complete

#EXPORTS:
isk.util=
  ChangeNotifier: ChangeNotifier
  when_ready: when_ready
