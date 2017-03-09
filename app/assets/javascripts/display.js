// This is a manifest file that'll be compiled into display.js, which will include all the files
// listed below.
//
// This file is used for the webgl based display.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
// Jquery
//= require jquery
//
// Three + plugins
//= require three
//= require THREEx.WindowResize
//= require THREEx.FullScreen
//
// State-machine
//= require state-machine
//
// Display javascripts, they care about the order
//= require ./display/isk.debug.js.coffee
//= require ./display/isk.local_message_broker.js.coffee
//= require ./display/isk.clock.js.coffee
//= require ./display/isk.renderer.js.coffee
//= require ./display/isk.client.js.coffee
//= require ./display/isk.remote_broker.js.coffee
//= require ./display/isk.errors.js.coffee
//= require ./display/isk.events.js.coffee
//= require ./display/isk.localoverride.js.coffee
//= require ./display/isk.videoplayer.js.coffee
//= require ./display/isk.statemachine.js.coffee
