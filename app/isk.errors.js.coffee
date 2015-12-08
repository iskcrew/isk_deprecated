@isk or= {}

errors = $('#errors')

connection = (active) ->
  console.log "ERR connection:", active
  if active
    errors.find('#connection').addClass('active')
  else
    errors.find('#connection').removeClass('active')

stopped = (active) ->
  console.log "ERR connection:", active
  if active
    errors.find('#stopped').addClass('active')
  else
    errors.find('#stopped').removeClass('active')

#EXPORTS:
@isk.errors =
  connection: connection
  stopped: stopped
