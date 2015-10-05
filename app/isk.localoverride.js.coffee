@isk or= {}

override = undefined
img = undefined
shown = false

set = (url) ->
  img.src=url

show = ->
  override.classList.add 'shown'

hide = ->
  override.classList.remove 'shown'

init = ->
  override = document.querySelector('#override')
  img = document.createElement('img')
  img.onload = ->
    show()
  override.appendChild img

  isk?.local_broker?.register 'show superoverride', set
  isk?.local_broker?.register 'hide superoverride', hide

setTimeout ->
  init()

#EXPORTS:
isk.localoverride=
  show: show
  hide: hide
  set: set
