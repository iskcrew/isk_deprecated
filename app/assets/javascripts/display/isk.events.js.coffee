@isk or= {}

escapetimeout=undefined
escape=3

reset_escape = ->
  escape=3

requestFullscreen = (elem) ->
  elem or= document.body
  f= elem.requestFullscreen ||
     elem.webkitRequestFullscreen ||
     elem.mozRequestFullScreen ||
     elem.msRequestFullscreen
  f(elem)

$(document).keypress (e) ->
  clearTimeout(escapetimeout)
  escapetimeout=setTimeout(reset_escape, 300)
  if e?.key == "Escape" or e?.key == "Esc"
    if --escape <= 0
      isk.fsm.exit()
      return false
  else
    reset_escape()
  return true

$('body').click (e) ->
  requestFullscreen()
  return false

$('#renderer').click (e) ->
  clearTimeout(escapetimeout)
  escapetimeout=setTimeout(reset_escape, 300)
  if --escape <= 0
    isk.fsm.exit()
    return false
  return true

$('#stopped').click (e) ->
  isk.fsm.run()
  return false
