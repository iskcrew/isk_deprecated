@isk or= {}

elem = undefined
time = undefined
shown = true
old_t = ""

init = ->
  elem=document.createElement('object')
  elem.type="image/svg+xml"
  elem.data="clock.svg"
  elem?.addEventListener 'load', ->
    svg=elem?.getSVGDocument()
    svg.querySelector('svg')?.setAttribute('viewBox', "0 0 1920 1080")
    clock=svg.querySelector('#clock')
    time=clock?.children[0]?.childNodes[0]
    run()
  document.querySelector('#ISKDPY div#clock').appendChild elem

show = ->
  elem.style='transition: 1s ease-in-out;transform: translateY(0)'
  shown=true

hide = ->
  elem.style='transition: 1s ease-in-out;transform: translateY(15%)'
  shown='hiding'
  setTimeout ->
    shown=false if shown == 'hiding'
  , 2000
  false

set_current_time = () ->
  if time? and shown
    t=Math.floor(Date.now()/1000)
    if t != old_t
      old_t = t
      s = Date().split(' ')
      ts = [s[0], s[4]].join ' '
      time?.nodeValue=ts

run = (t) ->
  requestAnimationFrame run
  set_current_time()

setTimeout ->
  init()

#EXPORTS:
isk.clock =
  show: show
  hide: hide
  elem: elem
