# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ($) ->
  
  # Show loader animation during slow loads
  $.fn.showLoader = (form) ->
    loader = $('<div class="loader hidden"><span class="loader_message">Working</span><br/><img src="/images/ajax-loader.gif"/></div>')
    $(this).after(loader)
    $(this).hide()
    $(loader).show()
    if form != true
      $(this).remove()
  
  killLoader = () ->
    $('.loader').each =>
      $(this).remove()
  
  $.fn.authoritySearch = ->
    # Global vars reset each time this is invoked - provides context within the desc_md form  
    authoritySearchVars = {}
    authoritySearchVars.link_href = $(this).attr('href')
    authoritySearchVars.linkClass = $(this).attr('class')
    authoritySearchVars.linkTitle = $(this).attr('title')
    authoritySearchVars.elementSection = $(this).parents('.has_authority_data').first()
    authoritySearchVars.displayContainer = $(this).parents('.authority_data_display').first()
    authoritySearchVars.elementId = $(authoritySearchVars.elementSection).attr('id')
    authoritySearchVars.valueField = $(authoritySearchVars.elementSection).find('input.value_field').first()
    authoritySearchVars.authorityField = $(authoritySearchVars.elementSection).find('input.authority_field').first()
    authoritySearchVars.valueUriField = $(authoritySearchVars.elementSection).find('input.value_uri_field').first()
    authoritySearchVars.authorityRecordIdField = $(authoritySearchVars.elementSection).find('input.authority_record_id_field').first()
    
    $.colorbox
      href: authoritySearchVars.link_href
      width: '800px'
      height: '650px'
      opacity: 0.8
      onComplete: =>
        $('form.dynamic_results_form').submit => 
          section = $(this).parents('.dynamic_section').first()
          container = $(section).find('.dynamic_content_container').first()
          oldContent = $(container).find('.dynamic_content').first()
      
          # $(oldContent).showLoader()       
      
          $.post($(this).attr("action"), $(this).serialize(), =>
            $(container).html(html)
            termSelector()
            killLoader()            
            false
          )
  
        false
   false


  # Helper function to copy data from selected term to metadata form
  
  termSelector = () ->
    $('.term_data_selector .select_term').click =>
      termJson = $(this).siblings('input[name="term_json"]').first().val()
      term_obj = $.parseJSON(termJson)
                
      $.colorbox.close()
    
      $(authoritySearchVars.valueField).attr('value',term_obj.term)
      $(authoritySearchVars.authorityField).attr('value',term_obj.authority)
      $(authoritySearchVars.valueUriField).attr('value',term_obj.valueUri)
      $(authoritySearchVars.authorityRecordIdField).attr('value',term_obj.authorityRecordId)
                  
      if (term_obj.nameType)
        $(authoritySearchVars.typeField).attr('value',term_obj.type)

      if (term_obj.latitude)
        $(authoritySearchVars.latitudeField).attr('value',term_obj.latitude)

      if (term_obj.longitude)
        $(authoritySearchVars.longitudeField).attr('value',term_obj.longitude)
                  
      displayText = term_obj.term + " (" + term_obj.authority + ")"
                
      newLink = $('<a></a>')

      $(newLink).attr({ 'href': authoritySearchVars.link_href, 'class': authoritySearchVars.linkClass, 'title': authoritySearchVars.linkTitle }).html('Select a different term')
      newTerm = $('<div class="authorized_term"></div>')
      $(newTerm).html(displayText)
    
      $(authoritySearchVars.displayContainer).html(newTerm).append(newLink)
      false
  # END - termSelector()
  
  
  $(document).ready ->
    $.fn.authoritySearchContentLoad = () ->
      section1 = $(this).parents('.dynamic_section').first()
      container1 = $(section1).find('.dynamic_content_container').first()
      oldContent1 = $(container1).find('.dynamic_content').first()
      $(oldContent1).showLoader()
      if $(this).is('a')
        content1 = $(this).attr('href')
        $(container1).load(content1, =>
          termSelector()
          killLoader()
          false
        )

      else if $(this).is('form')
        $.post($(this).attr("action"), $(this).serialize(), (html) =>
          $(container1).html(html)
          termSelector()
          killLoader()
          false
        )
        false
      false