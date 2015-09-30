@isk or= {}

override = undefined
img = undefined
shown = false

set = (url) ->
  img.src=url

show = ->
  override.style='transition: opacity 1s ease-in-out; opacity: 1'

hide = ->
  override.style='transition: opacity 1s ease-in-out; opacity: 0'

init = ->
  override = document.querySelector('#override')
  override.style='opacity: 0'
  img = document.createElement('img')
  img.onload = ->
    show()
  override.appendChild img

  isk.local_broker.register 'show superoverride', set
  isk.local_broker.register 'hide superoverride', hide

setTimeout ->
  init()

#EXPORTS:
isk.localoverride=
  show: show
  hide: hide
  set: set
