@isk or= {}

class PermanentData
  constructor: (@name, initial) ->
    if initial?
      localStorage.setItem(@name, initial)
  set: (value) ->
    localStorage.setItem(@name, value)
  get: ->
    localStorage.getItem(@name)
  clear: ->
    localStorage.removeItem(@name)

display_name = new PermanentData 'name'

init_displays = ->
  $('#ISKDPY #menu #displays').html '<ul />'
  $('#ISKDPY #menu #displays ul').click (e) ->
    name = $(e?.target).data('name')
    if name?
      display_name.set name
      isk.fsm.run()

hide_menu = ->
  $('#ISKDPY #menu').fadeOut()

show_menu = ->
  $('#ISKDPY #menu').fadeIn()

hide_displays = ->
  $('#ISKDPY #menu #displays ul').fadeOut()

show_displays = ->
  $.getJSON '/displays/?format=json'
    .done (displays) ->
      ul=$('#ISKDPY #menu #displays ul').html ""
      console.log "fetched displays", displays
      for d in displays
        ul.append "<li data-name='#{d?.name}'>#{d?.name} <br/><span>status: #{d?.status}</span></li>"
      ul.fadeIn()
      isk.fsm.conn_success()
    .fail ->
      ul=$('#ISKDPY #menu #displays ul').html ""
      console.log "error fetching displays"
      isk.fsm.conn_failed()

$ -> init_displays()

#EXPORTS:
@isk.menu=
  show: show_menu
  hide: hide_menu
  displays:
    show: show_displays
    hide: hide_displays
@isk.display_name=display_name

