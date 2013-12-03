
/*	NYPL Archives Platform
//	
//	view_nav_sticky.js
//
//	
//	Controls the sticky series and subseries headers
//
*/


(function() {

	"use strict";

	window.Archives.Views.navSticky = Backbone.View.extend({

		seriesLocations:        //where in the dom the series are located 
		{
			postions: [],
			texts: [],
			ids: [],
			descs: []
		},

		subseriesLocations:        //where in the dom the subseries are located 
		{
			postions: [],
			texts: [],
			ids: [],
			descs: []
		},

		activeSeriesId: -1,

		//the length in chars of where to cut off the popover series/subseries description
		//set in the config model
		trucatePopoverTextAt: null,

		//where the footer is located, updated after the content has been built, resize, etc
		footerLocation : -1,

		windowBottom : -1,


		initialize: function(){

			var self = this;

			this.trucatePopoverTextAt = Archives.a('trucatePopoverTextAt');

			this.render('','');

			this.buildSeriesLocations();



			//The tooltip for information of series and subseries in the sticky nav title
		    $('.title-tooltip').popover({ trigger: "hover", html: "true", placement: "right"});		

			//register listeners
			Archives.eventAgg.on('navSticky:buildSeriesLocations',this.buildSeriesLocations, this);

			//rebuild the series location index on change
			//Archives.eventAgg.on('global:containerListChanged',this.buildSeriesLocations,this);

			Archives.eventAgg.on('global:containerListChanged',function(){


				self = this;

					window.setTimeout(function(){ 

						self.buildSeriesLocations();
						self.checkStickyPositions();

						//also mark where the footer is
						self.footerLocation = $("#footer").offset().top;
						self.checkFooterPosition();

					}, 250);



			},this);




			Archives.eventAgg.on('global:resize',function(){
				window.setTimeout(function(){ 
					self.buildSeriesLocations();

				}, 10);

			},this);



			Archives.eventAgg.on("navSticky:inTransition", self.inTransition, this);





		},



		render: function(series,subseries) {

			var self = this;

			if (Archives.debugVerbose)
				console.log('view.navSticky.render', typeof series, subseries);


			//the reset 
			if (typeof series === 'string' && typeof subseries === 'string'  ){ 

				this.$el.find('#fixed-nav-title').html('');
				this.$el.find('#fixed-nav-subtitle').html('');
				this.$el.find('#fixed-nav-title-tooltip').css("display","none");
				this.$el.find('#fixed-nav-subtitle-tooltip').css("display","none");			
				return false;

			}


			if (typeof series === 'number'){
				this.$el.find('#fixed-nav-title').html(this.seriesLocations.texts[series]);	

				//we changed the series title see if we need to update the tooltip stuff

				if (self.seriesLocations.descs[series] !== ''){
					$('#fixed-nav-title-tooltip').data('popover').options.content = self.seriesLocations.descs[series];

					if (self.seriesLocations.descs[series].length > 800){
						$('#fixed-nav-title-tooltip').data('popover').options.placement = 'bottom';
					}else{
						$('#fixed-nav-title-tooltip').data('popover').options.placement = 'right'
					}

					$('#fixed-nav-title-tooltip').css("display","inline-block");
				}else{
					$('#fixed-nav-title-tooltip').css("display","none");				
				}

			}

			if (typeof series === 'string'){
				this.$el.find('#fixed-nav-title').html('');	
				$('#fixed-nav-title-tooltip').css("display","none");
			}


			if (typeof subseries === 'number'){ 
				this.$el.find('#fixed-nav-subtitle').html(this.subseriesLocations.texts[subseries]);

				if (self.subseriesLocations.descs[subseries] !== ''){
					$('#fixed-nav-subtitle-tooltip').data('popover').options.content = self.subseriesLocations.descs[subseries];

					if (self.subseriesLocations.descs[subseries].length > 800){
						$('#fixed-nav-subtitle-tooltip').data('popover').options.placement = 'bottom';
					}else{
						$('#fixed-nav-subtitle-tooltip').data('popover').options.placement = 'right'
					}

					$('#fixed-nav-subtitle-tooltip').css("display","inline-block");
				}else{
					$('#fixed-nav-subtitle-tooltip').css("display","none");				
				}
			}
			if (typeof subseries === 'string'){ 
				this.$el.find('#fixed-nav-subtitle').html('');
				$('#fixed-nav-subtitle-tooltip').css("display","none");	
			}






		},


		inTransition: function(){
			this.render('','');
			this.$el.css("visibility",'visible');
			this.$el.find('#fixed-nav-title').html('One moment please...');
		},


		/*
		//	Called when the container list changes, such as window resize or loading, builds an array of data to feed the sticky header 
		//	stored in Archives obj the arrays enable quick lookup of where in the series and subseries we are currently located
		//
		*/
		buildSeriesLocations: function(){

			if (Archives.debugVerbose)
			  console.log("viewNavSticky.buildSeriesLocations()");   

			this.seriesLocations.postions = [];
			this.seriesLocations.texts = [];
			this.subseriesLocations.postions = [];
			this.subseriesLocations.texts = [];


			this.seriesLocations.ids = [];
			this.subseriesLocations.ids = [];

			this.seriesLocations.descs = [];
			this.subseriesLocations.descs = [];

			this.conatinerListHeaderPos = 0;

			var self = this;

			_.each($('div.series'),function(e,i,l){

				var text = $(e).html().substring(0,$(e).html().search("<"));
				if (text == ''){
					text = $(e).html();
				}
				text = text.replace('&nbsp;','').replace('&amp;', '&');

				//make sure this one is not already added
				if (_.indexOf(self.seriesLocations.postions, $(e).offset().top) !== -1){return false;}


				self.seriesLocations.texts.push(text);

				self.seriesLocations.postions.push($(e).offset().top);


				self.seriesLocations.ids.push($(e).parent().parent().attr("id").replace("c",""));

				text = $(e).parent().children('.scopecontent').text();

				if (text.length>self.trucatePopoverTextAt)
					text=text.substring(0,self.trucatePopoverTextAt) + '...';

				self.seriesLocations.descs.push(text);






			});

			self.conatinerListHeaderPos = $('#fixed-nav-title').offset().top;

			_.each($('.remainder-width-2 .subseries'),function(e,i,l){
				//get the text only not the physdesc or other info
				var text = $(e).html().substring(0,$(e).html().search("<"));
				//or grab all of it if there was a problem
				if (text == ''){
					text = $(e).html();
				}
				//fix encoded chars
				text = text.replace('&nbsp;','').replace('&amp;', '&');

				//make sure this one is not already added
				if (_.indexOf(self.subseriesLocations.postions, $(e).offset().top) !== -1){return false;}

				if (text.length > 85){ text = text.substring(0,85) + "..."}
				self.subseriesLocations.texts.push(text);

				text = $(e).parent().children('.scopecontent').text();
				if (text.length>self.trucatePopoverTextAt)
				text=text.substring(0,self.trucatePopoverTextAt) + '...';

				self.subseriesLocations.descs.push(text);
				self.subseriesLocations.postions.push($(e).offset().top);
				self.subseriesLocations.ids.push($(e).parent().parent().attr("id").replace("c",""));



			});

		},


		checkFooterPosition: function(){


			this.windowBottom = $(window).scrollTop() +  $(window).height();

			if (this.windowBottom >= this.footerLocation){
				if (this.footerLocation !== -1 && Archives.navSide.footInViewport === false){

					Archives.eventAgg.trigger("navSide:footerPositionChange",true,false);
				}
			}else{
				if (this.footerLocation !== -1 && Archives.navSide.footInViewport === true){
					Archives.eventAgg.trigger("navSide:footerPositionChange",false,false);		
				}	
			}


		},




		checkStickyPositions: function(bubleEvent){

			var bubleEvent = (typeof bubleEvent === 'undefined') ? true : bubleEvent;

			var self = this;

			
			
			if (Archives.a('isFiltered')){return false;}
			


			//TODO checking the footer pos when filtered is crazy slow for some reason
			this.checkFooterPosition();





			if (!Archives.a('onDetailPage')){return false}

			if (!self.seriesLocations.postions){return false}

			if (self.seriesLocations.postions.length === 0){ return false }

			if (Archives.a('navScrolling')){ return false}	


		
			
			var headerElementHeight = $('#fixed-nav-title').height();
			var headerElementPos = $('#fixed-nav-title').offset().top;
			var headerElementSubPos = $('#fixed-nav-title').offset().top + ($('#fixed-nav-title').height()  * 1.5);
			var currentText = $("#fixed-nav-title").text();
			var currentSubtext = $("#fixed-nav-subtitle").text();


			if (headerElementPos < $(".navbar").first().outerHeight()){
				self.render('','');
				if (bubleEvent){
					Archives.eventAgg.trigger("navSide:activateNavItem", [self.seriesLocations.ids[0],false]);
				}
				$("#nav-title-holder").css("visibility",'hidden');
				return false;

			}


			//if we are before the first series remove the sticky and make sure the nav is good ( the -1 is because the style sheet actaully takes a min to kick in and it does change the height a tiny bit on some browsers)
			if (headerElementPos - 1 <= self.seriesLocations.postions[0]){
				self.render('','');
				if (bubleEvent){
					Archives.eventAgg.trigger("navSide:activateNavItem", [self.seriesLocations.ids[0],false]);
				}
				$("#nav-title-holder").css("visibility",'hidden');
				return false;
			}

			$("#nav-title-holder").css("visibility",'visible');
			
			
			for (var index = self.seriesLocations.postions.length; index >= 0 ; index = index  - 1) {
	 			if (headerElementPos + headerElementHeight + headerElementHeight > self.seriesLocations.postions[index]){
	 				if (currentText !== self.seriesLocations.texts[index]){


	 					self.activeSeriesId = self.seriesLocations.ids[index];
						self.render(index,'');

						if (bubleEvent){
							Archives.eventAgg.trigger("navSide:activateNavItem", [self.seriesLocations.ids[index],false]);
						}


						//does this one have subseries, check the series model
						if (Archives.allSeries.get(self.seriesLocations.ids[index])){
							if (typeof Archives.allSeries.get(self.seriesLocations.ids[index]).attributes.components != 'undefined'){
								self.navCheckSubseries = true;
							}else{
								self.navCheckSubseries = false;
								self.render(null,'');
							}
						}
					}
					break;
				}
			}


			if (self.subseriesLocations.postions[0]){
				if (headerElementPos < self.subseriesLocations.postions[0]){
					self.render(null,'');			
					return false;
				}
			}
	



			if (self.navCheckSubseries){
				for (var index = self.subseriesLocations.postions.length; index >= 0 ; index = index  - 1) {

		 			if (headerElementSubPos  > self.subseriesLocations.postions[index]){

		 				if (currentSubtext !== self.subseriesLocations.texts[index]){


		 					//check to make sure this sub series belongs to the current parent
		 					if (Archives.components[self.subseriesLocations.ids[index]]){


		 						if (parseInt(Archives.components[self.subseriesLocations.ids[index]].parent_id) === parseInt(self.activeSeriesId)){


		 							$("#fixed-nav-subtitle").show();

									if (self.subseriesLocations.descs){
										if (self.subseriesLocations.descs[index] !== ''){
											$("#fixed-nav-subtitle-tooltip").show();
										}	
									}

		 							self.render(null,parseInt(index));

		 							if (bubleEvent){
		 								Archives.eventAgg.trigger("navSide:activateNavItem", [self.subseriesLocations.ids[index],false]);
		 							}
		 							
		 							
		 						}else{

		 							self.render(null,'');


		 						}


		 					}
		 					
		 				}else{
		 					$("#fixed-nav-subtitle").show();

		 					if (self.subseriesLocations.descs){
		 						if (self.subseriesLocations.descs[index] !== ''){
		 							$("#fixed-nav-subtitle-tooltip").show();
		 						}	
		 					}
		 						 					
		 				}




						return false;
					}
				}


			}



		}





	});

}).call(this);