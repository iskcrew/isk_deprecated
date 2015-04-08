@isk or= {}

elem = undefined
svg = undefined
time = undefined
shown = true
old_t = ""

init = ->
  elem=$('<object type="image/svg+xml" data="clock.svg"></object>')
  elem[0]?.addEventListener 'load', ->
    svg=$(elem[0]?.getSVGDocument())
    svg.find('svg')[0]?.setAttribute('viewBox', "0 0 1920 1080")
    time=svg.find('#clock')
    run()
  elem.appendTo $('#ISKDPY #clock')

show = ->
  elem.animate {top: "0%"},
    start: ->
      elem.show()
      shown=true

hide = ->
  elem.animate {top: "15%"},
    done: ->
      elem.hide()
      shown=false

set_current_time = ->
  if time? and shown
    t=Date()
    if t != old_t
      old_t = t
      s = t.split(' ')
      ts = [s[0], s[4]].join ' '
      time?.text ts

run = ->
  requestAnimationFrame run
  set_current_time()

$ ->
  init()

#EXPORTS:
isk.clock =
  show: show
  hide: hide
