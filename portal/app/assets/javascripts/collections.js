// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).ready(function(){

  $('.footnote-link').each(function() {


    id_href = $(this).attr('href');
    content = $(id_href).clone().html();

    $(this).popover( { 'content': content, 'html': true, 'trigger': 'hover' } );


    $(this).click(function(e){



    	$("html, body").animate({ scrollTop: $($(this).attr('href')).offset().top - $(".navbar").first().outerHeight() }, "fast")

    	e.preventDefault();
    	return false;

    	
    });


  });
});