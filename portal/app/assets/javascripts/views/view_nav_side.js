
/*	NYPL Archives Platform
//	
//	view_nav_side.js
//
//	The view for the side navigation (nav by series/subseries) controls scrolling when clicked and maintaining the active indicator of the sub/series
//	
//
*/


(function() {

	"use strict";


	window.Archives.Views.navSide = Backbone.View.extend({

		//the active component
		activeComponentId : -1,
		activeNavSeries : 0,
		activeNavSubseries : 0,
		scrolling : false,
		isChangingSeries : false,


		//is the footer in view, changes the way we size the sidenav bar
		footInViewport : false,


		builtNav : {},

		events: {

			//clicking on a series or subseries
			'click li' : 'navToSelection',

		},

		changingSeries: function(val){

			this.isChangingSeries = val;

		},

		initialize: function(){

			var self = this;

			if (Archives.a('buildOwnNav')){
				this.builtNav = Archives.collectionStructure;
				this.builtNav.components = [];
			}


			//register listeners
			Archives.eventAgg.on('navSide:activateNavItem',this.activateNavItem, this);

			Archives.eventAgg.on('global:resize',this.sizeNavContainer, this);

			Archives.eventAgg.on('navSide:footerPositionChange', this.adjustForFooter, this);

			Archives.eventAgg.on('navSide:hide', this.hide, this);

			
			Archives.ask.set('activeComponentId',function(){return self.activeComponentId;});
			Archives.ask.set('activeNavSeries',function(){return self.activeNavSeries;});
			Archives.ask.set('activeNavSubseries',function(){return self.activeNavSubseries;});
			Archives.ask.set('footInViewport',function(){return self.footInViewport;});

			Archives.ask.set('navScrolling',function(){return self.scrolling;});

			


			this.render();
		},

		hide: function(){

			this.$el.hide();


		},

		render: function() {
			if (Archives.debugVerbose)
				console.log('view.navSide.render');

			var templateFunction = _.template(window.Archives.templates['navSide']);
			var html = templateFunction({model: Archives.collectionStructure, templateFunction: templateFunction });
			this.$el.html(html);

			$(window).resize();

		},


		adjustForFooter: function(inView){

			if (inView){
				this.footInViewport = true;
			}else{
				this.footInViewport = false;
			}

			this.sizeNavContainer();
		},


		//When they click on a link to a series or subseries
		navToSelection: function(e){
			this.activeComponentId = $(e.target).attr("href").replace('#c','');

			//emit events to  drive the next steps
			Archives.eventAgg.trigger("navSide:activateNavItem",this.activeComponentId);
	 
			e.preventDefault;
			return false;
		},




		activateNavItem: function(activeComponentId){

			var self = this;

			if (this.isChangingSeries)return false;

			if (typeof activeComponentId === 'object'){
				var scroll = activeComponentId[1];
				activeComponentId = activeComponentId[0];
			}else{
				var scroll = true;
			}




			//don't scroll again if we are already active in this series
			if (activeComponentId === this.activeNavSeries){
				return false;
			}


			if (Archives.components[activeComponentId]){

				/*if (Archives.components[activeComponentId].level_text === 'series'){

					//if we are getting signals to nav to an not


					return false;
				}*/

				if (Archives.components[activeComponentId].level_text === 'series'){
					$(".nav-subseries-container").slideUp();
				}


				if ($("#nav-subseries-container-" + activeComponentId).length > 0){
					$(".nav-subseries-container").slideUp();
					$("#nav-subseries-container-" + activeComponentId).slideDown();
				}

				$(".nav-series-li, .nav-subseries-li").removeClass("active").removeClass('nav-subseries-li-active');

				//style it
				if (Archives.components[activeComponentId].level_text === 'series'){
					$('a[href="#c'+activeComponentId+'"]').parent().addClass("active");
					this.activeNavSeries = activeComponentId;
				}else{
					$('a[href="#c'+activeComponentId+'"]').parent().addClass("nav-subseries-li-active");
					$('a[href="#c'+Archives.components[activeComponentId].parent_id+'"]').parent().addClass("active");
					this.activeNavSubseries = activeComponentId;
				}
				


				if (Archives.a('renderMode') === 'series'){
					//are they loding a new series or sub navigating this one?
					if (Archives.components[activeComponentId].level_text == 'series' && Archives.a('isFiltered') === false){

						//trigger the load series event
						if (scroll){

							//Archives.navSticky.seriesLocations = [];
							//Archives.navSticky.subseriesLocations = [];

							self.scrolling = false;
							Archives.allSeries.get(activeComponentId).view.render();

						}
					}
				}



				if (Archives.a('isFiltered')){
					//do not do the whole thing for just scroll
					$("html, body").animate({ scrollTop: $("#collection-content-searchresults #c" + activeComponentId).offset().top - 400}, "fast");
					return	
				}
				
				if (scroll){


					if ($("#c" + activeComponentId).offset()){

		 				self.scrolling = true;

		
						var nudge = $(".navbar").first().outerHeight();

		 				if (Archives.components[activeComponentId].level_text === 'subseries'){
							//if we are scrolling to a subseries make sure the title has something in it so it can account for its size
							//in the calculation of where to nudge to
							if ($("#fixed-nav-subtitle").html() === ''){
								$("#fixed-nav-subtitle").html("&nbsp;");
							}


							nudge = $(".navbar").first().outerHeight()  + ($("#fixed-nav-subtitle").outerHeight()) + 10;			
						}





		 				$("html, body").animate({ scrollTop: $("#c" + activeComponentId).offset().top - nudge}, "fast", function(){


		 					//prevent  interference from the sticky header popping off change events while we are auto scrolling, the delay is to make sure it happens after 
		 					//the sticky check scroll event
		 					window.setTimeout(function(){


		 						Archives.navSticky.checkStickyPositions(false);

		 						self.scrolling=false;	


		 						if (Archives.components[activeComponentId].level_text === 'series'){
		 							$("#nav-title-holder").css("visibility","hidden");
		 						}else{

		 							$("#nav-title-holder").css("visibility","visible");
		 							$("#fixed-nav-subtitle").hide();
		 							$("#fixed-nav-subtitle-tooltip").hide();
		 						}
		 						

		 					}, 200);
		 						

		 				});

					}
				}

			}else{

				if (!Archives.components){

					//the components are not event initalized yet
					window.setTimeout(function(){

						self.activateNavItem();


					},100);

				}else{

					if (_.size(Archives.components) !== 0){

						//console.error("compnent does not exist: ", activeComponentId,Archives.components)
					}

				}


			}


		},



		sizeNavContainer: function(){

			if (Archives.debug)
				console.log("viewNavSide.sizeNavContainer");


			if (Archives.a('buildOwnNav') && Archives.collectionStructure.components.length===0){
				$("#nav-detailed-list").hide();
			}else{
				$("#nav-detailed-list").show();
			}

			
			$("#nav-detailed-container").show();
			$("#nav-title-holder").show();


			$("#nav-title-holder").css("width",$("#collection-content-detailed").width());

			
			if (this.footInViewport){
				$("#nav-detailed-container").css("height", $(window).height() - $(".navbar").first().height() - $("#nav-filter").height() - $("#footer").outerHeight());
			}else{
				$("#nav-detailed-container").css("height", $(window).height() - $(".navbar").first().height() - $("#nav-filter").height());
			}

			$("#nav-detailed-container").css("width",$("#nav-detailed-container").parent().width() + 10);


		},



	    buildCustomNav: function(){

	       var self = this;


	       var c01 = {}, c01Children = {};


	        _.each(Archives.components, function(element, index, list){

	          //is it a level one compo? Add it to the object to rember we need to check for subseries later, push to the structure response
	          if (element.level_num === 1 ){

	              self.builtNav.components.push(element);
	              element.level_text = 'series';              
	              Archives.components[element.id].level_text = 'series';

	              //update the html which would have been rendered at this point
	              $("#c" + element.id + ' .title').addClass("series").removeClass("file");
	              $("#c" + element.id).addClass('margin-series');

	              if (typeof c01[element.id] == 'undefined'){
	                c01[element.id] = 0;
	                c01Children[element.id] = [];
	                
	              }
	                   
	          }




	          if (element.level_num === 2 ){

	              //is it the child of a compo we are intrested in (series)?
	              if (typeof c01[element.parent_id] !== 'undefined'){
	                c01[element.parent_id]++;
	              }
	          }
	        
	        });


	        _.each(Archives.components, function(element, index, list){



	          if (element.level_num === 2 && (element.has_children || element.child_ids)){
	            if (typeof c01[element.parent_id] !== 'undefined'){
	          
	              //are the less then X c02 compoenents then it is eligble for a subseries nav
	              if (c01[element.parent_id] <= 10){
	                c01Children[element.parent_id].push(element);
	                element.level_text = 'subseries';              
	                Archives.components[element.id].level_text = 'subseries';
	                $("#c" + element.id + ' .title').addClass("subseries").removeClass("file");
	                $("#c" + element.id).addClass("margin-subseries");



	              }
	            }
	          }


	        });



	        //loop through the compoents on the structure and add in the subseries if warrented
	        _.each(self.builtNav.components, function(element, index, list){
	          if (c01Children[element.id].length !== 0){
	            self.builtNav.components[index].components = c01Children[element.id];
	          }    
	        });



	        Archives.eventAgg.trigger('global:containerListChanged');
	    },



	});

}).call(this);