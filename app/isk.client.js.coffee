@isk or= {}

root=document.querySelector('#ISKDPY #pres')
if not (root?) then return

debug=false
timer=undefined
display_id=undefined

current=root.getElementsByClassName('current')
presentation=root.getElementsByClassName('presentation_slide')
overrides=root.getElementsByClassName('override_slide')

#TODO fix this hack later
showing_override=false

class ChangeNotifier
  constructor: (initial, callback) ->
    @state = initial
    @cb = callback
  set: (state) ->
    if @state != state
      @state = state
      @cb state
  get: () ->
    @state

manual_mode = new ChangeNotifier false, (manual) ->
  if manual
    clearTimeout(timer)
  else
    dur=current?[0]?.iskSlide?.duration
    if dur?
      timer=setTimeout(timed_next_slide, dur*1000) if dur > 0

clock_mode = new ChangeNotifier true, (clock) ->
  if clock
    isk.clock.show()
  else
    isk.clock.hide()

create_slide = (slide) ->
  if slide?.group?
    gs_id="slide_G#{slide.group}S#{slide.id}"
    gs_class="presentation_slide"
  else
    gs_id="slide_O#{slide.override_queue_id}S#{slide.id}"
    gs_class="override_slide"
  img=document.createElement('img')
  img.id=gs_id
  img.classList.add(gs_class)
  img.src= "/slides/#{slide?.id}/full?t=#{slide?.images_updated_at}"
  img.iskSlide = slide
  img.iskSlide.uid="#{slide?.id}_#{slide?.images_updated_at}"
  img

handle_hello = (display) ->
  display_id=display?.id
  if display_id?
    channel=isk.dispatcher.subscribe 'display_'+display_id
    channel.bind 'data', callback=handle_display
    channel.bind 'goto_slide', callback=handle_goto_slide

    handle_display display
    timed_next_slide()

handle_display = (display) ->
  console.debug "received display",  display
  
  isk?.local_broker?.trigger 'presentation_changed', display
  
  overs=document.createElement('div')
  overs.id='overrides'
  overs.appendChild create_slide s for s in display?.override_queue

  elems=document.createElement('div')
  elems.id='presentation'
  elems.appendChild create_slide s for s in display?.presentation?.slides

  if display?.presentation?.slides?.length == 0
    console.log "Presentation is empty"
    empty=document.querySelector('#empty').cloneNode()
    empty.iskSlide = {duration: 1, ready: true}
    empty.dataset.error_message ='Presentation empty, showing empty slide'
    empty.appendTo elems

  [].forEach.call current, (s) ->
    old_slide = s
    if old_slide?
      id = old_slide.id
      console.debug 'Marking current slide', id
      new_slide = elems.children[id]
      if new_slide?
        new_slide.classList.add('current')
        if (not showing_override) and (old_slide?.iskSlide?.images_updated_at <
            new_slide?.iskSlide?.images_updated_at)
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

send_hello = (name) ->
  console.debug "sending_hello", name
  isk.dispatcher.trigger 'iskdpy.hello', {display_name: name},
    success = (d) -> handle_hello d,
    failure = (d) -> alert 'Websocket failed'

send_shutdown = (display_id) ->
  data = { display_id: display_id }
  console.debug 'sending shutdown', data
  isk.dispatcher.trigger 'iskdpy.shutdown', data

send_current_slide = (slide) ->
  s=slide.iskSlide
  data = {
    display_id: display_id,
    group_id: s?.group
    slide_id: s?.id,
    override_queue_id: s?.override_queue_id
    }
  if data?.slide_id and (data?.group_id or data?.override_queue_id)
    console.debug 'sending current_slide', data
    isk.dispatcher.trigger 'iskdpy.current_slide', data
  else
    data.error = slide.dataset?.error_message or "Unknown slide shown"
    console.debug 'sending error', data
    isk.dispatcher.trigger 'iskdpy.error', data

send_error = (msg) ->
  data = {
    display_id: display_id,
    error: msg
  }
  console.debug 'sending error', data
  isk.dispatcher.trigger 'iskdpy.error', data
  
# TODO remove jquery
when_ready = (elem, f) ->
  $(elem).one 'load', f
  .each -> $(@).load() if @complete

#when_ready = (elem, cb) ->
#  elem.addEventListener 'load', f = (e) ->
#    e.target.removeEventListener(e.type, arguments.callee)
#    cb(e)
#  f.apply(elem) if elem.complete

set_current = (elem) ->
  clearTimeout(timer)
  if elem? and elem?.iskSlide?.ready
    console.debug 'CURRENT', elem
    when_ready elem, ->
      if @?.width
        send_current_slide @
        showing_override=elem?.classList?.contains('override_slide')
        [].forEach.call @.parentElement.getElementsByClassName('current'), (e) ->
          e.classList.remove('current')
          e.classList.remove('updated')
        @.classList.add('current')
        clock_mode.set @?.iskSlide?.show_clock == true
        dur=@?.iskSlide?.duration
        if dur
          timer=setTimeout(timed_next_slide, dur*1000) if not manual_mode.get()
      else
        send_error "Unknown error in slide image (#{@.id})"
        timer=setTimeout(timed_next_slide, 1000) if not manual_mode.get()
  else timer=setTimeout(timed_next_slide, 1000) if not manual_mode.get()
  undefined

set_current_updated = (elem) ->
  console.debug 'UPDATED', elem
  if elem? and elem?.iskSlide?.ready
    clearTimeout(timer)
    when_ready elem, ->
      if @?.width
        send_current_slide @
        [].forEach.call @.parentElement.getElementsByClassName('updated'), (e) ->
          e.classList.remove('updated')
        @.classList.add('updated')
        clock_mode.set @?.iskSlide?.show_clock == true
        dur=@?.iskSlide?.duration
        if dur
          timer=setTimeout(timed_next_slide, dur*1000) if not manual_mode.get()
      else
        send_error "Unknown error in slide image (#{@.id})"
        timer=setTimeout(timed_next_slide, 1000) if not manual_mode.get()
  undefined

prev_slide = ->
  prev=current?[0]?.previousElementSibling
  if (not prev?)
    [..., last] = presentation
    prev=last
  set_current(prev)

next_slide = ->
  next=overrides?[0]
  if (not next?)
    next=current?[0]?.nextElementSibling
  if (not next?)
    [first, ...] = presentation
    next=first
  set_current(next)

goto_slide = (id) ->
  next=presentation?[id]
  set_current(next)

timed_next_slide = ->
  next_slide()

start_client = (name) ->
  $('#ISKDPY #renderer').fadeIn()
  send_hello name

stop_client = ->
  $('#ISKDPY #renderer').fadeOut()
  if display_id?
    isk.dispatcher.unsubscribe "display_"+display_id
    send_shutdown display_id
    display_id=undefined
  root?.innerHtml = ""

#EXPORTS:
@isk.client=
  start: start_client
  stop: stop_client
  prev_slide: prev_slide
  next_slide: next_slide
  goto_slide: goto_slide

