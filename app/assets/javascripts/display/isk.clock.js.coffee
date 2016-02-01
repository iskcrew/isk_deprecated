@isk or= {}

elem = undefined
ctx = undefined
time = undefined
shown = true
old_t = ""

t_pos = [1650, 90]
t_size = "60px"

longday =
	Mon: "Monday"
	Tue: "Tueday"
	Wed: "Wedday"
	Thu: "Thursday"
	Fri: "Friday"
	Sat: "Saturday"
	Sun: "Sunday"

init = ->
	elem=document.createElement('canvas')
	ctx=elem.getContext('2d')
	elem.width=1920
	elem.height=128

	ctx.font = t_size + " 'CustomFont'"
	ctx.fillStyle = '#FFF'
	ctx.strokeStyle = '#000'
	ctx.lineWidth = 3
	ctx.miterLimit = 2

	run()
	document.querySelector('#ISKDPY div#clock').appendChild elem

show = ->
	elem.classList.remove 'hidden'
	shown=true

hide = ->
	elem.classList.add 'hidden'
	shown='hiding'
	setTimeout ->
		shown=false if shown == 'hiding'
	, 2000
	false

drawStrokedText = (t, pos...) ->
	ctx.fillText(t, pos...)
	ctx.strokeText(t, pos...)

set_current_time = () ->
	if shown
		t=Math.floor(Date.now() / 1000)
		if t != old_t
			old_t = t
			s = Date().split(' ')
			ts = [s[0], s[4]].join ' '
			#drawStrokedText(ts)
			ctx.clearRect(0, 0, elem.width, elem.height)
			drawStrokedText(longday[s[0]], t_pos[0], 60 )
			drawStrokedText(s[4], t_pos[0], 115)

run = (t) ->
	requestAnimationFrame run
	set_current_time()

setTimeout ->
	init()

#EXPORTS:
isk.clock =
	show: show
	hide: hide
