isk?.local_broker?.register 'presentation_changed', (data) ->
	console.log 'Presentation changed'
	fields= document.querySelectorAll('#presroot * span')
	fields[0].innerHTML=data?.name
	fields[1].innerHTML=data?.presentation?.name
	fields[2].innerHTML=data?.override_queue?.length
	fields[3].innerHTML=data?.presentation?.total_slides

svgNS = "http://www.w3.org/2000/svg"
xmlNS = "http://www.w3.org/XML/1998/namespace"

edit=document.querySelector('#o_editor')
preview=document.querySelector('#o_preview')
preview.src='/backgrounds/empty.png'

img=document.createElement('img')
img.src='/backgrounds/empty.png'

canvas=document.createElement('canvas')
ctx=canvas.getContext('2d')

[canvas.width,canvas.height]=[1920,1080]

drawStroked = (args...) ->
	ctx.textBaseline = 'top'
	ctx.font = "100pt CustomFont"
	ctx.fillStyle = '#FFF'
	ctx.strokeStyle = '#000'
	ctx.lineWidth = 4
	ctx.miterLimit = 2
	
	ctx.fillText(args...)
	ctx.strokeText(args...)

drawMultilineText = (text, x, y, h) ->
	lines=text.split /\r\n|\n|\r/
	for line, index in lines
		if line == ""
			y+=30
		else
			drawStroked line, x, y
			y+=120

set = (text) ->
	ctx.drawImage img, 0, 0
	drawMultilineText text, 40, 40
	canvas.toBlob (blob)->
		durl=URL.createObjectURL blob
	
		preview.ready = ->
			URL.revokeObjectURL durl
		preview.src=durl

document.querySelector('#o_update').addEventListener 'click', ->
	console.debug 'Update Super Override'
	set edit.value

document.querySelector('#o_show').addEventListener 'click', ->
	console.debug 'Show Super Override'
	isk?.local_broker?.trigger 'show superoverride', preview.src

document.querySelector('#o_hide').addEventListener 'click', ->
	console.debug 'Hide Super Override'
	isk?.local_broker?.trigger 'hide superoverride'

player=document.querySelector '#player'
input=document.querySelector '#player input'
selector=document.querySelector '#player select#select'
time=document.querySelectorAll '#player #time *'
buffer=document.querySelectorAll '#player #buffer *'
queue=document.querySelector 'table #queue'
template=document.querySelector 'template#queue_line'

add_line_to_queue = (id, name) ->
	l=document.importNode template.content, true
	l.querySelector '.name'
		.textContent=name
	l.querySelectorAll 'span'
		.textContent=""
	l.children[0].id=id
	queue.appendChild l
	undefined

isk?.local_broker?.register 'video canplaythrough', (id) ->
	queue.querySelector("##{id} .state").classList.add 'canplaythrough'

isk?.local_broker?.register 'video ended', (id) ->
	queue.querySelector("##{id}").remove()
	setTimeout play_next, 3000

isk?.local_broker?.register 'video timeupdate', (id, ctime, dur) ->
	if dur
		left=dur-ctime
		if ctime > 0.01
			queue.querySelector("##{id} .state").classList.add 'playing'
		if left < 0.01
			queue.querySelector("##{id} .state").classList.add 'ended'
		queue.querySelector("##{id} .ctime").textContent=ctime.toFixed(1)
		queue.querySelector("##{id} .time").textContent=dur.toFixed(1)
		queue.querySelector("##{id} .ltime").textContent=left.toFixed(1)
		queue.querySelector("##{id} .position").value=ctime / dur

isk?.local_broker?.register 'video progress', (id, ctime, dur) ->
	if dur
		left=dur-ctime
		if left<=0.01
			queue.querySelector("##{id} .state").classList.add 'finished'
		queue.querySelector("##{id} .buffer").value=ctime / dur

input.addEventListener 'change', ->
	file=input.files[0]
	if file
		furl=URL.createObjectURL file
		o=document.createElement 'option'
		o.value=furl
		o.innerHTML=file.name
		selector.appendChild o

button=(name, click) ->
	e=document.createElement 'button'
	e.innerHTML=name
	e.onclick=click
	player.appendChild e
	e

play_next= ->
	selected=document.querySelector '#queue .line'
	if selected?
		isk?.local_broker?.trigger 'video play', selected.id
	else
		isk?.local_broker?.trigger 'hide superoverride'

play= ->
	isk?.local_broker?.trigger 'show superoverride', 'poster.png'
	setTimeout play_next, 5000

@b=
	maxid: 0
	queue: button 'queue', ->
		selected=document.querySelectorAll '#select option:checked'
		id="vid" + b.maxid++
		add_line_to_queue id, selected[0].textContent
		isk?.local_broker?.trigger 'video prepare', id, selected[0].value
	play: button 'play queued', play
	pause: button 'toggle pause', ->
		isk?.local_broker?.trigger 'video pause'

shaders=undefined
sname=document.querySelector('#s_name')
stype=document.querySelector('#s_type')
scode=document.querySelector('#s_code')

isk?.local_broker?.register 'return shaders', (data) ->
	shaders=data
	sname.innerHTML=""
	for name, value of shaders
		o=document.createElement('option')
		o.innerHTML=name
		sname.appendChild(o)

document.querySelector('#s_load').addEventListener 'click', ->
	scode.value = shaders[sname.value][stype.value]
document.querySelector('#s_apply').addEventListener 'click', ->
	shaders[sname.value][stype.value] = scode.value
	isk?.local_broker?.trigger 'set shaders', shaders

isk?.local_broker?.trigger 'get shaders'
