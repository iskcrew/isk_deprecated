@isk or= {}

videos={}

player=document.querySelector('#override')
isk?.local_broker?.register 'video play', (id) ->
  v=videos[id]
  player.appendChild(v)
  v.play()

isk?.local_broker?.register 'video pause', (f) ->
  v=document.querySelector('body video')
  if v?
    if v.paused
      v.play()
    else
      v.pause()

isk?.local_broker?.register 'video prepare', (id, f, name) ->
  v=document.createElement('video')
  v.src=f
  v.id=id
  v.preload="auto"
  videos[id]=v
  isk?.local_broker?.trigger 'video prepared', id, f, name

  v.addEventListener 'timeupdate', (e) ->
    isk?.local_broker?.trigger 'video timeupdate', @id, @currentTime, @duration
  
  v.addEventListener 'progress', (e) ->
    if @buffered.length
      isk?.local_broker?.trigger 'video progress', @id, @buffered.end(0), @duration
  
  v.addEventListener 'canplaythrough', (e) ->
    isk?.local_broker?.trigger 'video canplaythrough', @id

  v.addEventListener 'loadedmetadata', (e) ->
    if @buffered.length
      isk?.local_broker?.trigger 'video progress', @id, @buffered.end(0), @duration
    isk?.local_broker?.trigger 'video timeupdate', @id, @currentTime, @duration
  
  v.addEventListener 'ended', (e) ->
    isk?.local_broker?.trigger 'video ended', @id
    delete videos[@id]
    @remove()
