@isk or= {}

if not SharedWorker?
  return

worker=undefined
port=undefined
cbs={}

open_port = () ->
  worker = new SharedWorker($('#ISKDPY').attr('data-local-worker'))
  worker.port.start()
  worker.port

port or= open_port()

port.onmessage = (e) ->
  cbs[e.data[0]]?(e.data[1]...)

register= (name, cb) ->
  cbs[name]=cb

trigger= (name, data...) ->
  port.postMessage([name, data])

# EXPORTS
@isk.local_broker=
  register: register
  trigger: trigger
  port: port
