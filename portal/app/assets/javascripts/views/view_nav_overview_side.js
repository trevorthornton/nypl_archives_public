/*	NYPL Archives Platform
//	
//	view_nav_overview_side.js
//
//	
//	The overview side bar nav.
//
*/

(function() {

	"use strict";


	window.Archives.Views.navOverviewSide = Backbone.View.extend({


		events: {
			'click li a' : 'click',
		},


		positions : [],



		click : function(e){

			var targetHref = $(e.target).attr('href');
			var target = $(targetHref);

			var nudge = $(".navbar").first().outerHeight();

			$("html, body").animate({ scrollTop: target.offset().top - nudge}, "fast");




			Archives.allRoutes.navigate(targetHref, {trigger: true, replace: true});


			e.preventDefault();
			return false;



		},


		initialize: function(){

			Archives.eventAgg.on("global:scrolling", this.checkPos,this);
			Archives.eventAgg.on("global:resize", this.buildPos, this);
			Archives.eventAgg.on("global:routeOverview", this.buildPos, this);
			


			this.buildPos();

			window.setTimeout(this.checkPos,500);

		},


		buildPos : function(){

			var self = this;



			window.setTimeout(function(){
				//store the positions of all the headers
				$(".scrollto-section").each(function(i,e){
					self.positions.push({id: $(e).attr('id'), pos: $(e).offset().top - $(".navbar").first().outerHeight() - 100});
				});

				self.checkPos();

			},500);


		},

		checkPos : function (){



			if (!Archives.a('onDetailPage')){

				var scrollTop = $(window).scrollTop();

				var last = false;

				_.each(this.positions, function(e,i){



					if (scrollTop >= e.pos){
						last = e;
					}


				});




				if (last){
					$("#navTab li").removeClass("active");
					$('#navTab a[href="#' + last.id + '"]').parent().addClass("active");
				}



			}




		},


		render: function() {

			


		},






	});

}).call(this);