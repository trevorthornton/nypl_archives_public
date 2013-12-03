/*	NYPL Archives Platform
//	
//	nav_viz_control.js
//
//	The controler for the minimap
//	
//
*/


(function () {



   "use strict";

	window.Archives.Views.navVizControl = Backbone.View.extend({

		showing: false,
		pageLoaded: false,
		rendered: false,



		events : {
			"click"		: "click"
		},


		initialize: function() {

			var self = this;

			Archives.eventAgg.on('data:pageLoaded', this.setPageLoaded, this);

			Archives.eventAgg.on("global:routeDetailed",this.show,this);
			Archives.eventAgg.on("global:routeOverview",this.hide,this);

			//set the place holder
			$("#viz-nav-loading-placeholder").css("top",$(".nav-top").first().outerHeight(true) + $("#nypl-header").first().outerHeight(true) + 2);
			$("#viz-nav-loading-placeholder").css("height", $(window).height() - $(".nav-top").first().outerHeight(true) + $("#nypl-header").first().outerHeight(true) + 2);

			$(this.el).tooltip(
				{
					placement: 'left',
					trigger: "hover",
					html: true,
					title : "Click to toggle the minimap: <br> A navigation tool to quickly move through the finding aid."
				}
			);

			if (navigator.userAgent.match(/iPad/i) !== null){
				$("#viz-nav-loading-placeholder").remove();
				$(this.el).remove();
			}


			Archives.ask.set('minimapShowing',function(){return self.showing;});

		},





		show: function(){


			//do they have canvas?
			if (!!window.HTMLCanvasElement){
				$(this.el).css("visibility", 'visible');

				if (this.rendered){
					$("#iframe-minimap").css("visibility", 'visible');
					Archives.viznav.iframeBody.css("visibility", 'visible');

				}
			}


		},

		hide: function(){

			
				$(this.el).css("visibility", 'hidden');
			if (this.rendered){
				$("#iframe-minimap").css("visibility", 'hidden');
				Archives.viznav.iframeBody.css("visibility", 'hidden');
			}

		},

		click : function(e){

			if (this.pageLoaded){

				$(this.el).tooltip('destroy');


				if(this.showing){

					 $("#iframe-minimap").animate({
					    right: -1 * Archives.viznav.displayWidth
					  }, 500, function() {
					    $("#viz-nav-control").html('<i class="icon-chevron-left"></i><i class="icon-chevron-left"></i');
					  });

					 $("#viz-nav-control").animate({
					    right: 0
					  }, 500, function() {
					    $("#viz-nav-control").html('<i class="icon-chevron-left"></i><i class="icon-chevron-left"></i');
					  });


					 this.showing = false;

				}else{

					if (!this.rendered){
							

						window.setTimeout(function(){Archives.viznav.init();},600);
						

						$("#viz-nav-control, #viz-nav-loading-placeholder").animate({
							right: "+=" + (Archives.viznav.displayWidth)
						}, 500, function() {
							$("#viz-nav-control").html('<i class="icon-chevron-right"></i><i class="icon-chevron-right"></i');
							
						});


					}else{

						$("#viz-nav-control,#iframe-minimap").animate({
							right: "+=" + (Archives.viznav.displayWidth)
						}, 500, function() {
							$("#viz-nav-control").html('<i class="icon-chevron-right"></i><i class="icon-chevron-right"></i');
						});


					}


					this.showing = true;
					this.rendered = true;

				}

			}
			



		},


		setPageLoaded: function(){

			this.pageLoaded = true;

			if (Archives.a('onDetailPage')){
				this.show();
			}

		}





	});

}());