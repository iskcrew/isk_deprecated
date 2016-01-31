@isk or= {}

errors = $('#errors')

error = (id, name, active) ->
  console.log "ERR #{name}:", active
  if active
    errors.find("##{id}").addClass('active')
  else
    errors.find("##{id}").removeClass('active')

#EXPORTS:
@isk.errors =
  connection: error.bind(this, 'connection', 'Connection')
  stopped: error.bind(this, 'stopped', 'Display stopped')
  loggedout: error.bind(this, 'loggedout', 'Login Failed')
