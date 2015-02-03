@isk = @isk || {}

send_login = (username, password) ->
  $.post "/login?format=json", {username: username, password: password}
    .fail (d) ->
      console.log 'Login failed', d?.responseJSON?.message
    .done (data) ->
      if data?.message
        isk.show_choise()

send_logout = ->
  $.post "/login?format=json", {_method: "delete"}
    .success show_login

show_login = ->
  $('#ISKDPY #choise h1').html "ISK-DPY Login"
  ul=$('#ISKDPY #choise #logout').html ""
  ul=$('#ISKDPY #choise ul').html ""
  ul.append '<li><label>Username:</label><input type="text" id="username" /></li>'
  ul.append '<li><label>Password:</label><input type="password" id="password" /></li>'
  ul.append '<li><label> </label><input type="submit" id="submit" value="Login"/></li>'
  $('#ISKDPY #choise #submit').click (e) ->
    send_login $('#ISKDPY #choise #username').val(), $('#ISKDPY #choise #password').val()

show_logout = ->
  $('#ISKDPY #logout')
   .html '<a>(Logout)</a>'
   .children().click send_logout

# EXPORTS:
@isk.show_login=show_login
@isk.show_logout=show_logout

