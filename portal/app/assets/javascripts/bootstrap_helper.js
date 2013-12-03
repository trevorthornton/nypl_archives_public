



// Borrowed from response.js - see https://github.com/ryanve/response.js/issues/17
var correctedViewportW = (function (win, docElem) {
  var mM = win['matchMedia'] || win['msMatchMedia']
    , client = docElem['clientWidth']
    , inner = win['innerWidth']
  return mM && client < inner && true === mM('(min-width:' + inner + 'px)')['matches']
      ? function () { return win['innerWidth'] }
      : function () { return docElem['clientWidth'] }
  }(window, document.documentElement));

function headerOffset() {
  var x = $('.navbar').height();
  return x;
}

// Modify body padding to support variable-height sticky header
function offsetBody(offset) { 
  var viewportCutoffWidth = 980;
  var bodyPadding = headerOffset();
  
  function bodyPaddingTop() {
    return $('body').css('padding-top');
  }
  function addBodyPadding() {
    $('body').css('padding-top', bodyPadding + 'px');
  }
  function removeBodyPadding() {
    $('body').css('padding-top', 0);
  }
  
  // Remove padding on window resize below 981
  function adjustBodyPaddingOnResize() {
    $(window).resize(function() {
      if ((correctedViewportW() < viewportCutoffWidth) && (bodyPaddingTop() != 0)) {
        removeBodyPadding();
      } else if ((correctedViewportW() > viewportCutoffWidth) && (bodyPaddingTop() != bodyPadding)) {
        addBodyPadding();
      }
    });
  }
  if (correctedViewportW() > viewportCutoffWidth) {
    addBodyPadding();
  }
  adjustBodyPaddingOnResize();
}

// See http://blog.jeremymartin.name/2008/02/jtruncate-text-truncation-for-jquery.html
function simpleTruncate() {
  $(document).on('click', '.truncate a.truncate-link', function(e) {
    var truncateWrapper = $(this).parents('.truncate').first();
    $(truncateWrapper).find('.truncate-text').toggleClass('hidden');
    e.preventDefault();
  });
}


function searchDigitalContentToolTip(){
  $(".has-digital-content-icon-holder").tooltip({placement: 'right'});
}


$(document).ready(function() {
  offsetBody();
  searchDigitalContentToolTip();
  simpleTruncate();
});

/*
//incoporated into backbone app 10/4


function sidenavScroller() {
  
  function getTargetPosition(elem,point) {
		var id = elem.attr("href");
		var offset = headerOffset();
		if (point == 'bottom') {
		  return $(id).offset().bottom - offset;
		} else {
		  return $(id).offset().top - offset;
	  }
	}
	
	var links = $('.sidenav a[href^="#"]');
  var items = $('.sidenav li');
  
	function checkSectionSelected(scrolledTo){

    //add a hook to disable this if we are not in the overview page,
    if (window.Archives.disable_overview_scroll){return false;}

		var threshold = 30;
		var i;
		for (i = 0; i < links.length; i++) {
			var link = $(links[i]);
			var item = $(link).parent();
			var targetTop = getTargetPosition(link);
      if (scrolledTo > targetTop - threshold && scrolledTo < targetTop + threshold) {
        items.removeClass("active");
        item.addClass("active");
      }
		};
	}

	// Check if page is already scrolled to a section.
	checkSectionSelected($(window).scrollTop());

	$(window).scroll(function(e){
		checkSectionSelected($(window).scrollTop())
	});
  
  $(document).on('click', 'a[data-toggle="scrollto"]', function(e) {
    var targetHref = $(this).attr('href');
    var sidenav = $('.sidenav').first();
    var navLink = $('.sidenav a[href="' + targetHref + '"]');
    var navItem = $(navLink).parents('li').first();
     var targetHref = $(this).attr('href');
    var target = $(targetHref);
    $(sidenav).find('.active').first().toggleClass('active');
    
    $(navItem).toggleClass('active');
    
    $('html, body').animate({
      scrollTop: ($(target).offset().top-headerOffset())
    }, 200);
    e.preventDefault();
  });
}





$(document).ready(function() {
  offsetBody();
  sidenavScroller();
  simpleTruncate();
});




*/
