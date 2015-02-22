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
  name=display_name.get()
  if name?
    isk.start_client name
    hide_menu()
  else
    isk.close_client()
    show_menu()
  $('#ISKDPY #menu #displays ul').click (e) ->
    name = $(e?.target).data('name')
    if name?
      display_name.set name
      isk.start_client name
      hide_menu()

hide_menu = ->
  $('#ISKDPY #menu').fadeOut()
  hide_displays()

show_menu = ->
  $('#ISKDPY #menu').fadeIn()
  show_displays()

hide_displays = ->
  $('#ISKDPY #menu #displays ul').fadeOut()

show_displays = ->
  ul=$('#ISKDPY #menu #displays ul').html ""
  $.getJSON '/displays/?format=json'
    .done (displays) ->
      console.log "fetched displays", displays
      for d in displays
        ul.append "<li data-name='#{d?.name}'>#{d?.name} <br/><span>status: #{d?.status}</span></li>"
      ul.fadeIn()
      isk.show_logout()
    .fail ->
      console.log "error fetching displays"
      isk.show_login()


escapetimeout=undefined
escape=3

reset_escape = ->
  escape=3

$(document).keypress (e) ->
  clearTimeout(escapetimeout)
  escapetimeout=setTimeout(reset_escape, 300)
  if e?.key == "Escape" or e?.key == "Esc"
    if --escape <= 0
      display_name.clear()
      isk.close_client()
      show_menu()
      return false
  else
    reset_escape()
  return true
    

$ -> init_displays()

#EXPORTS:
@isk.menu=
  show: show_menu
  hide: hide_menu
  displays:
    show: show_displays
    hide: hide_displays
@isk.display_name=display_name

