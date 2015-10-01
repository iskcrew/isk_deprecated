@isk or= {}

elem = undefined
ctx = undefined
time = undefined
shown = true
old_t = ""

t_pos = [1450, 1020]
t_size = "70px"

init = ->
  elem=document.createElement('canvas')
  ctx=elem.getContext('2d')
  elem.width=1920
  elem.height=1080

  ctx.font = t_size + " 'CustomFont'"
  ctx.fillStyle = '#FFF'
  ctx.strokeStyle = '#000'
  ctx.lineWidth = 4
  ctx.miterLimit = 2

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

drawStrokedText = (t) ->
  ctx.clearRect(0, 0, elem.width, elem.height)
  ctx.fillText(t, t_pos[0], t_pos[1])
  ctx.strokeText(t, 1450, 1020)

set_current_time = () ->
  if shown
    t=Math.floor(Date.now()/1000)
    if t != old_t
      old_t = t
      s = Date().split(' ')
      ts = [s[0], s[4]].join ' '
      drawStrokedText(ts)

run = (t) ->
  requestAnimationFrame run
  set_current_time()

setTimeout ->
  init()

#EXPORTS:
isk.clock =
  show: show
  hide: hide
