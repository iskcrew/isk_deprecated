@isk or= {}

errors = $('#errors')

connection = (active) ->
  console.log "ERR connection:", active
  if active
    errors.find('#connection').addClass('active')
  else
    errors.find('#connection').removeClass('active')

#EXPORTS:
@isk.errors =
  connection: connection
