$(document).ready ->
	
	$.fn.removeFromList = (params) ->
		optionValue = $(this).attr('title')
		option = $(params.options).find('.option[title="' + optionValue + '"]').first()
		$(option).show()
		$(this).remove()
		
	$.fn.addToList = (params) ->
		selection = $(this).clone()
		selection.find('a.select_remove').html('Remove')
		$(params.selections).append(selection)
		$(selection).addClass('selection').removeClass('option')
		$(this).hide()
		
	$('.list_builder').each ->
		params =
			options: $(this).find('.options').first()
			selections: $(this).find('.selections').first()
		
		$(this).on 'click', '.option a.select_remove', ->
			option = $(this).parents('.option').first()
			$(option).addToList(params)
		
		$(this).on 'click', '.selection a.select_remove', ->
			selection = $(this).parents('.selection').first()
			$(selection).removeFromList(params)
			
		$(this).parents('form').first().submit ->
			$(params.options).remove()