@isk or= {}

worker=undefined
port=undefined
cbs={}

open_port = () ->
  worker = new SharedWorker('app/isk.local_message_broker_worker.js')
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
