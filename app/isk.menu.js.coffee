@isk = @isk || {}

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

init_choise = ->
  $('#ISKDPY #choise').html '<h1></h1><span id="logout"/><ul></ul>'
  name=display_name.get()
  if name?
    isk.start_client name
    hide_choise()
  else
    isk.close_client()
    show_choise()
  $('#ISKDPY #choise ul').click (e) ->
    name = $(e?.target).data('name')
    if name?
      display_name.set name
      isk.start_client name
      hide_choise()

hide_choise = ->
  $('#ISKDPY #choise').hide()

show_choise = ->
  $('#ISKDPY #choise').show()
  $('#ISKDPY #choise h1').html ""
  ul=$('#ISKDPY #choise ul').html ""
  $.getJSON '/displays/?format=json'
    .done (displays) ->
      console.log "fetched displays", displays
      $('#ISKDPY #choise h1').html 'Select display:'
      for d in displays
        ul.append "<li data-name='#{d?.name}'>#{d?.name} <br/><span>status: #{d?.status}</span></li>"
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
    

$ -> init_choise()

#EXPORTS:
@isk.show_choise=show_choise
@isk.display_name=display_name

