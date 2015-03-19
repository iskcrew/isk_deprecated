@isk or= {}

elem = undefined
svg = undefined
time = undefined

init = ->
  elem=$('#ISKDPY #clock').first()
  svg=$(elem.find('object')[0]?.getSVGDocument())
  svg.find('svg')[0]?.setAttribute('viewBox', "0 0 1920 1080")
  time=svg.find('#clock')

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
  if time?.length
    run()

#EXPORTS:
isk.clock={show: show, hide: hide}
