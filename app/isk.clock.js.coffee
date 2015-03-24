@isk or= {}

elem = undefined
svg = undefined
time = undefined

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

hide = ->
  elem.animate {top: "15%"},
    done: ->
      elem.hide()

set_current_time = ->
  t=Date().split(' ')
  ts = [t[0], t[4]].join ' '
  if time.text() != ts
    time.text ts

run = ->
  requestAnimationFrame run
  set_current_time()

$ ->
  init()

#EXPORTS:
isk.clock =
  show: show
  hide: hide
