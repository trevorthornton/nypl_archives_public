
/*	NYPL Archives Platform
//	
//	admin_links.js
//
//	
//	Show thoes admin links, yeah
//
*/


(function() {

	"use strict";


	window.Archives.Views.adminLinks = Backbone.View.extend({



		initialize: function() {

			var self = this;

			Archives.eventAgg.on('global:adminLinks',function(){
				
				self.render();

			});

			
		},



		render: function() {


			$(".collection-detailed-row").each(function(i,e){
				$(e).find('.container-desc').find('div').prepend($("<i>").addClass('icon-cog').addClass('admin-links').css("font-style","normal").css("position","absolute"));
			});


			//bind to that thing

			$('.admin-links').each(function(i,e){

				var html = '<a target="_blank" href="' + window.location.origin + window.location.pathname + "#" + $(e).parent().parent().parent().attr("id") + '"><i class="icon-share"></i>&nbsp;&nbsp;Perm Link</a>' + '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + '<a target="_blank" href="' + window.location.origin.replace('archives.','data.archives.') + '/components/'  + $(e).parent().parent().parent().attr("id").replace('c','') + '"><i class="icon-wrench"></i>&nbsp;Data Page</a>';

				$(e).popover({content: html, placement: 'right', html: true});

				$(e).click(function(){
					$('.admin-links').each(function(i2,e2){
						if (e != e2)
							$(e2).popover('hide');
					});
				});

			});




		}

	});

}).call(this);