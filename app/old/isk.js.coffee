$ ->
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

  class PermanentData
    constructor: (@name, initial) ->
      if initial?
        localStorage.setItem(@name, initial)
    set: (value) ->
      localStorage.setItem(@name, value)
    get: ->
      localStorage.getItem(@name)
    clear: ->
      localStorage.removeItem(@name)


  display_name = new PermanentData 'name'

  manual_mode = new ChangeNotifier false, (manual) ->
    if manual
      clearTimeout(timer)
    else
      dur=root.find('.current').first().data()?.slide?.duration
      if dur?
        timer=setTimeout(timed_next_slide, dur*1000) if dur > 0

  handle_hello = (display) ->
    display_id=display?.id
    if display_id?
      channel=window.dispatcher.subscribe 'display_'+display_id
      channel.bind 'data', callback=handle_display
      channel.bind 'goto_slide', callback=handle_goto_slide

      handle_display display
      timed_next_slide()

  handle_display = (display) ->
    console.log "received display",  display
    slide = (slide) ->
      if slide?.group?
        gs_id="slide_G#{slide.group}S#{slide.id}"
      else gs_id="slide_O#{slide.override_queue_id}S#{slide.id}"
      img=$('<img/>')
      img.attr
        id: gs_id,
        src: "/slides/#{slide?.id}/preview?t=#{slide?.images_updated_at}"
      img.data 'slide', slide
      
    overrides=$('<div id="override"/>')
    overrides.append slide s for s in display?.override_queue

    elems=$('<div id="presentation"/>')
    elems.append slide s for s in display?.presentation?.slides

    if display?.presentation?.slides?.length == 0
      console.log "Presentation is empty"
      $('#empty').clone()
        .data('slide', {duration: 1})
        .data('error_message', 'Presentation empty, showing empty slide')
        .appendTo elems

    old_slide = root.find('#presentation .current').first()
    if old_slide.length
      id = old_slide.attr('id')
      console.log 'Marking current slide', id
      new_slide = elems.find('#'+id)
      new_slide.addClass('current')
      if (old_slide.data()?.slide?.images_updated_at <
          new_slide.data()?.slide?.images_updated_at)
        set_current_updated new_slide
    root.html overrides.add(elems)

    manual_mode.set display?.manual == true

  handle_goto_slide = (d) ->
    console.log "received goto_slide", d
    if d?.slide == "next" then next_slide()
    else if d?.slide == "previous" then prev_slide()
    else
      elem=$("#slide_G#{d?.group_id}S#{d?.slide_id}")
      if elem.length then set_current(elem)
    true

  send_hello = (name) ->
    console.log "sending_hello", name
    window.dispatcher.trigger 'iskdpy.hello', {display_name: name},
      success = (d) -> handle_hello d,
      failure = (d) -> alert 'Websocket failed'

  send_shutdown = (display_id) ->
    data = { display_id: display_id }
    console.log 'sending shutdown', data
    dispatcher.trigger 'iskdpy.shutdown', data
  
  send_current_slide = (slide) ->
    d=$(slide).data()
    data = {
      display_id: display_id,
      group_id: d?.slide?.group
      slide_id: d?.slide?.id,
      override_queue_id: d?.slide?.override_queue_id
      }
    if data?.slide_id and (data?.group_id or data?.override_queue_id)
      console.log 'sending current_slide', data
      dispatcher.trigger 'iskdpy.current_slide', data
    else
      data.error = d?.error_message or "Unknown slide shown"
      dispatcher.trigger 'iskdpy.error', data

  when_ready = (elem, f) ->
    $(elem).one 'load', f
    .each -> $(@).load() if @complete

  set_current = (elem) ->
    clearTimeout(timer)
    if elem.length
      when_ready elem, ->
        $(@).siblings('.current').removeClass('current')
        $(@).addClass('current')
        send_current_slide @
        dur=$(@).data()?.slide?.duration
        if dur
          timer=setTimeout(timed_next_slide, dur*1000) if not manual_mode.get()
    else timer=setTimeout(timed_next_slide, 1000) if not manual_mode.get()
  
  set_current_updated = (elem) ->
    console.log 'UPDATED', elem
    if elem.length and elem.data('slide')?.ready
      clearTimeout(timer)
      when_ready elem, ->
        $(@).siblings('.updated').removeClass('updated')
        $(@).addClass('updated')
        send_current_slide @
        dur=$(@).data()?.slide?.duration
        if dur
          timer=setTimeout(timed_next_slide, dur*1000) if not manual_mode.get()

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
    $('#ISKDPY #canvas').fadeIn()
    send_hello name

  close_client = ->
    $('#ISKDPY #canvas').fadeOut()
    if display_id?
      dispatcher.unsubscribe "display_"+display_id
      send_shutdown display_id
      display_id=undefined
    root?.html ""

  send_login = (username, password) ->
    $.post "/login?format=json", {username: username, password: password}
      .fail (d) ->
        console.log 'Login failed', d?.responseJSON?.message
      .done (data) ->
        if data?.message
          show_choise()

  show_login = ->
    $('#ISKDPY #choise h1').html "ISK-DPY Login"
    ul=$('#ISKDPY #choise ul').html ""
    ul.append '<li><label>Username:</label><input type="text" id="username" /></li>'
    ul.append '<li><label>Password:</label><input type="password" id="password" /></li>'
    ul.append '<li><label> </label><input type="submit" id="submit" value="Login"/></li>'
    $('#ISKDPY #choise #submit').click (e) ->
      send_login $('#ISKDPY #choise #username').val(), $('#ISKDPY #choise #password').val()

  init_choise = ->
    $('#ISKDPY #choise').html "<h1></h1><ul></ul>"
    name=display_name.get()
    if name?
      start_client name
    else
      close_client()
      show_choise()
    $('#ISKDPY #choise ul').click (e) ->
      name = $(e?.target).data('name')
      if name?
        display_name.set name
        start_client name

  show_choise = ->
    $('#ISKDPY #choise h1').html ""
    ul=$('#ISKDPY #choise ul').html ""
    $.getJSON '/displays/?format=json'
      .done (displays) ->
        console.log "fetched displays", displays
        $('#ISKDPY #choise h1').html 'Select display: <a data-method="delete" href="/login" rel="nofollow">(Logout)</a>'
        for d in displays
          ul.append "<li data-name='#{d?.name}'>#{d?.name} <br/><span>status: #{d?.status}</span></li>"
      .fail ->
        console.log "error fetching displays"
        show_login()
    
  $(document).keypress (e) ->
    if e?.ctrlKey and e?.key == "Esc"
      display_name.clear()
      close_client()
      show_choise()

  init_choise()
