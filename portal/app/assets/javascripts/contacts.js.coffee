# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ($) ->
  $(document).ready ->
    $('.contact-link').colorbox(
      height: '600px',
      width: '600px',
      opacity: 0.8 )
    
    $(document).bind 'cbox_open', ->
      $('html').css({ overflow: 'hidden' })
    $(document).bind 'cbox_closed', ->
      $('html').css({ overflow: '' })