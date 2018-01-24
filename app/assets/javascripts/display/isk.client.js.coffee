@isk or= {}

root=document.querySelector('#ISKDPY #pres')
if not (root?) then return

debug=false
timer=undefined
running=undefined

current=root.getElementsByClassName('current')
current_pres=root.getElementsByClassName('presentation_slide current')
current_over=root.getElementsByClassName('override_slide current')
presentation=root.getElementsByClassName('presentation_slide')
overrides=root.getElementsByClassName('override_slide')

manual_mode = new isk.util.ChangeNotifier false, (manual) ->
  if manual
    clearTimeout(timer)
  else
    dur=current?[0]?.iskSlide?.duration
    if dur?
      timer=setTimeout(timed_next_slide, dur*1000) if dur > 0

clock_mode = new isk.util.ChangeNotifier true, (clock) ->
  if clock
    isk.clock?.show()
  else
    isk.clock?.hide()

create_slide = (slide) ->
  elem=undefined
  if slide?.type == 'image'
    elem=create_img_slide(slide)
  else if slide?.type == 'video'
    elem=create_video_slide(slide)
  else
    return elem


  if slide?.group?
    elem.id="slide_G#{slide.group}S#{slide.id}"
    elem.classList.add("presentation_slide")
  else
    elem.id="slide_O#{slide.override_queue_id}S#{slide.id}"
    elem.classList.add("override_slide")
  elem

create_img_slide = (slide) ->
  img=document.createElement('img')
  img.src= "#{slide?.media_url}?t=#{slide?.images_updated_at}"
  img.iskSlide=slide
  img.iskSlide.uid="#{slide?.id}_#{slide?.images_updated_at}"
  img

create_video_slide = (slide) ->
  video=document.createElement('video')
  source=document.createElement('source')
  video.appendChild(source)

  source.src= "#{slide?.media_url}"
  video.iskSlide=slide
  video.iskSlide.uid="#{slide?.id}_#{slide?.updated_at}"
  video

handle_start = (data) ->
  console.debug "received start",  data
  running=true
  timed_next_slide()

handle_display = (display) ->
  console.debug "received display",  display

  isk.local_broker?.trigger 'presentation_changed', display

  overs=document.createElement('div')
  overs.id='overrides'
  overs.appendChild create_slide s for s in display?.override_queue

  elems=document.createElement('div')
  elems.id='presentation'
  elems.appendChild create_slide s for s in display?.presentation?.slides

  if display?.presentation?.slides?.length == 0
    console.log "Presentation is empty"
    empty=document.querySelector('#empty').cloneNode()
    empty.iskSlide = {duration: 1, ready: true, effect_id: 1}
    empty.dataset.error_message ='Presentation empty, showing empty slide'
    empty.classList.add "presentation_slide"
    elems.appendChild empty

  [].forEach.call current, (old_slide, index) ->
    if old_slide?
      id = old_slide.id
      console.debug 'Marking current slide', id
      new_slide = elems.children[id] or overs.children[id]
      if new_slide?
        new_slide.classList.add('current')
        if (index == 0) and (old_slide?.iskSlide?.images_updated_at < new_slide?.iskSlide?.images_updated_at)
          set_current_updated new_slide

  while (root?.firstChild?)
    root.removeChild(root.firstChild)

  root.appendChild overs
  root.appendChild elems

  manual_mode.set display?.manual == true

handle_goto_slide = (d) ->
  console.debug "received goto_slide", d
  if d?.slide == "next" then next_slide()
  else if d?.slide == "previous" then prev_slide()
  else goto_slide "slide_G#{d?.group_id}S#{d?.slide_id}"
  true

send_start = ->
  console.debug "sending_start"
  isk.remote.trigger 'start'

send_shutdown = ->
  console.debug 'sending shutdown'
  isk.remote.trigger 'shutdown'

_send_slide_info = (method, slide) ->
  s=slide?.iskSlide
  data = {
    group_id: s?.group
    slide_id: s?.id,
    override_queue_id: s?.override_queue_id
    }
  if data?.slide_id and (data?.group_id or data?.override_queue_id)
    console.debug 'sending', method, data
    isk.remote.trigger method, data
  else
    data.error = slide?.dataset?.error_message or "Unknown slide shown"
    console.debug 'sending error', data
    isk.remote.trigger 'error', data

send_current_slide = (slide) ->
  _send_slide_info 'current_slide', slide

send_slide_shown = (slide) ->
  if slide?
    _send_slide_info 'slide_shown', slide

send_error = (msg) ->
  console.debug 'sending error', msg
  isk.remote.trigger 'error', error: msg

_set_slide_timeout = (dur) ->
  if dur and not manual_mode.get()
    timer=setTimeout(timed_next_slide, dur*1000)

_set_current = (elem, cname='current') ->
  elem.classList.add(cname)
  send_current_slide elem
  clock_mode.set elem?.iskSlide?.show_clock == true
  _set_slide_timeout elem?.iskSlide?.duration
  elem

set_current = (elem) ->
  console.debug 'CURRENT', elem
  clearTimeout(timer)
  current?[0]?.classList?.remove('override_slide')
  send_slide_shown current?[0]
  if elem.nodeName == 'VIDEO'
    elem.currentTime=0
    elem.pause()

  if elem? and elem?.iskSlide?.ready
    isk.util.when_ready elem, ->
      if @?.width or @?.videoWidth
        [].forEach.call @.parentElement.getElementsByClassName('current'), (e) ->
          e.classList.remove('current')
          e.classList.remove('updated')
          if e.nodeName == 'VIDEO'
            e.pause()
        _set_current @
        if elem.nodeName == 'VIDEO'
          elem.play()
      else
        send_error "Unknown error in slide image (#{@.id})"
        _set_slide_timeout 1
  else _set_slide_timeout 1
  undefined

set_current_updated = (elem) ->
  console.debug 'UPDATED', elem
  if elem? and elem?.iskSlide?.ready
    clearTimeout(timer)
    isk.util.when_ready elem, ->
      if @?.width
        [].forEach.call @.parentElement.getElementsByClassName('updated'), (e) ->
          e.classList.remove('updated')
        _set_current @, 'updated'
      else
        send_error "Unknown error in slide image (#{@.id})"
        _set_slide_timeout 1
  undefined

prev_slide = ->
  prev=current_pres?[0]?.previousElementSibling
  if (not prev?)
    [..., last] = presentation
    prev=last
  set_current(prev)

next_slide = ->
  if (current_over?.length == 0)
    next=overrides?[0]
  if (not next?)
    next=overrides?[1]
  if (not next?)
    next=current_pres?[0]?.nextElementSibling
  if (not next?)
    [first, ...] = presentation
    next=first
  set_current(next)

goto_slide = (id) ->
  next=presentation?[id]
  set_current(next)

timed_next_slide = ->
  next_slide()

start_client = ->
  $('#ISKDPY #renderer').fadeIn()
  isk.remote.register object:'display', method:'start', handle_start
  isk.remote.register object:'display', method:'data', handle_display
  isk.remote.register object:'display', method:'goto_slide', handle_goto_slide
  send_start()

stop_client = ->
  $('#ISKDPY #renderer').fadeOut()
  if running?
    send_shutdown()
    running=undefined
  clearTimeout(timer)
  root?.innerHtml = ""

#EXPORTS:
@isk.client=
  start: start_client
  stop: stop_client
  prev_slide: prev_slide
  next_slide: next_slide
  goto_slide: goto_slide

