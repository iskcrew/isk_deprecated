@isk or= {}

root=$('#ISKDPY #pres').first()
if not (root?) then return

debug=false
timer=undefined
display_id=undefined
 
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
    dur=root.find('.current').first().data()?.slide?.duration
    if dur?
      timer=setTimeout(timed_next_slide, dur*1000) if dur > 0

clock_mode = new ChangeNotifier true, (clock) ->
  if clock
    isk.clock.show()
  else
    isk.clock.hide()

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
  slide = (slide) ->
    if slide?.group?
      gs_id="slide_G#{slide.group}S#{slide.id}"
    else gs_id="slide_O#{slide.override_queue_id}S#{slide.id}"
    img=$('<img/>')
    img.attr
      id: gs_id,
      src: "/slides/#{slide?.id}/full?t=#{slide?.images_updated_at}"
    img.data 'slide', slide
    
  overrides=$('<div id="override"/>')
  overrides.append slide s for s in display?.override_queue

  elems=$('<div id="presentation"/>')
  elems.append slide s for s in display?.presentation?.slides

  if display?.presentation?.slides?.length == 0
    console.log "Presentation is empty"
    $('#empty').clone()
      .data('slide', {duration: 1, ready: true})
      .data('error_message', 'Presentation empty, showing empty slide')
      .appendTo elems

  old_slide = root.find('#presentation .current').first()
  if old_slide.length
    id = old_slide.attr('id')
    console.debug 'Marking current slide', id
    new_slide = elems.find('#'+id)
    new_slide.addClass('current')
    if (old_slide.data()?.slide?.images_updated_at <
        new_slide.data()?.slide?.images_updated_at)
      set_current_updated new_slide
  root.html overrides.add(elems)

  manual_mode.set display?.manual == true

handle_goto_slide = (d) ->
  console.debug "received goto_slide", d
  if d?.slide == "next" then next_slide()
  else if d?.slide == "previous" then prev_slide()
  else
    elem=$("#slide_G#{d?.group_id}S#{d?.slide_id}")
    if elem.length then set_current(elem)
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
  d=$(slide).data()
  data = {
    display_id: display_id,
    group_id: d?.slide?.group
    slide_id: d?.slide?.id,
    override_queue_id: d?.slide?.override_queue_id
    }
  if data?.slide_id and (data?.group_id or data?.override_queue_id)
    console.debug 'sending current_slide', data
    isk.dispatcher.trigger 'iskdpy.current_slide', data
  else
    data.error = d?.error_message or "Unknown slide shown"
    console.debug 'sending error', data
    isk.dispatcher.trigger 'iskdpy.error', data

send_error = (msg) ->
  data = {
    display_id: display_id,
    error: msg
  }
  console.debug 'sending error', data
  isk.dispatcher.trigger 'iskdpy.error', data
  

when_ready = (elem, f) ->
  $(elem).one 'load', f
  .each -> $(@).load() if @complete

set_current = (elem) ->
  clearTimeout(timer)
  if elem.length and elem.data('slide')?.ready
    when_ready elem, ->
      if @?.width
        send_current_slide @
        $(@).addClass('current').siblings('.current').removeClass('current')
        clock_mode.set $(@).data()?.slide?.show_clock == true
        dur=$(@).data()?.slide?.duration
        if dur
          timer=setTimeout(timed_next_slide, dur*1000) if not manual_mode.get()
      else
        send_error "Unknown error in slide image (#{@.id})"
        timer=setTimeout(timed_next_slide, 1000) if not manual_mode.get()
  else timer=setTimeout(timed_next_slide, 1000) if not manual_mode.get()

set_current_updated = (elem) ->
  console.debug 'UPDATED', elem
  if elem.length and elem.data('slide')?.ready
    clearTimeout(timer)
    when_ready elem, ->
      if @?.width
        send_current_slide @
        $(@).addClass('updated').siblings('.updated').removeClass('updated')
        clock_mode.set $(@).data()?.slide?.show_clock == true
        dur=$(@).data()?.slide?.duration
        if dur
          timer=setTimeout(timed_next_slide, dur*1000) if not manual_mode.get()
      else
        send_error "Unknown error in slide image (#{@.id})"
        timer=setTimeout(timed_next_slide, 1000) if not manual_mode.get()

prev_slide = ->
  prev=$('.current').prev('img')
  if (prev.length == 0)
    prev=$('#pres img:last')
  set_current(prev)

next_slide = ->
  next=$('#pres #override img:first')
  if (next.length == 0)
    next=$('.current').next('img')
  if (next.length == 0)
    next=$('#pres img:first')
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
  root?.html ""

#EXPORTS:
@isk.client=
  start: start_client
  stop: stop_client
  prev_slid: prev_slide
  next_slide: next_slide

