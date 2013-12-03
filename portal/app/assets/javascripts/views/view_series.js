
/*	NYPL Archives Platform
//	
//	view_series.js
//
//	
//	The view for series rendering
//
*/


(function() {

	"use strict";


	window.Archives.Views.series = Backbone.View.extend({



		initialize: function() {
			//don't reneder until it is ready
			//this.listenTo(this.model, "change", this.render);
			if (window.Archives.debugVerbose)
				console.log('view.initalize');
			
		},



		render: function() {

			if (Archives.a('blockingAction')){


				//There is a blocking action because it is rendering but we can stop that if they are trying to nav to a series that is ready
				if (this.model.get('ready')){
					Archives.data.cancel();
				}else{
					//they have to wait until it is ready at least
					return false;
				}
			}
			Archives.navSide.changingSeries(true);
				

			var self = this;
			
			//let ask now wer are changing active series
			Archives.ask.set('activeSeries',this.model.get('id'));

			//unset by the domInsertComplete event
			Archives.ask.set('blockingAction',true);

			//var templateFunction = _.template(window.Archives.templates['skeleton']);
			//var templateComponentFunction = _.template(Archives.templates['singleComponent']);

			//reset the refence object counter
			//this.model.set('blockCounter',{count: -1});

			//var html = templateFunction({model: this.model.get('collectionStructure'), templateFunction: templateFunction, templateComponentFunction: templateComponentFunction, counter: this.model.get('blockCounter')});
			
			var html = '';

			var totalBlocks = parseInt(this.model.get('total_components') / Archives.a('componentsPerPass'));
			if (this.model.get('total_components') % Archives.a('componentsPerPass') > 0) totalBlocks++;

			if (totalBlocks<1)totalBlocks=1;

			for (var x = 0; x < totalBlocks; x++){
				html += '<div class="collection-detailed-block"></div>';
			}


			/*
			//the collection structure only extends to the 3rd depth, some crazy big series have up to c06 levels.
			//if we know we did not add enough blocks add in the missing ones.
			if (this.model.get("blockCounter").count < this.model.get('total_components')){
				

				var leftovers = (this.model.get('total_components') - this.model.get("blockCounter").count);
				var numberOfBlocks = 0;
				if (leftovers % Archives.a('componentsPerPass') > 0) numberOfBlocks++;

				numberOfBlocks = numberOfBlocks + (parseInt(leftovers/Archives.a('componentsPerPass')));				

				console.log(leftovers, parseInt(leftovers/Archives.a('componentsPerPass')), numberOfBlocks);



			}
			*/

			Archives.eventAgg.trigger("navSticky:inTransition");

			//update thte element
			this.$el = $("#collection-content-detailed");

			//naviage to the top of the page
			$(window, document).scrollTop(0);



			//fade out container
			this.$el.fadeOut('fast', function(){


				//our function it cuting the element out of the dom, and then placing back in
				//so esentially it is a new dom, so update our model reference

				self.$el = $(Archives.data.replaceHtml(self.$el.get(0), html));

				self.$el.fadeIn('fast');

				//tell the data module its got some rendering to do
				Archives.data.seriesChangeRender(self.model.get('id'));

				Archives.eventAgg.trigger("global:containerListChanged");


			});














			//Archives.eventAgg.trigger("global:containerListChanged");

			/*

			if (window.Archives.isDeepLinking)
				return false;

			//remove linebreaks and multiple spaces

			var templateFunction = _.template(window.Archives.templates['series']);
			var templateComponentFunction = _.template(window.Archives.templates['singleComponent']);

			window.Archives.activeSeries = this.model.attributes.id;

			var html = templateFunction({model: this.model.attributes, templateFunction: templateFunction, templateComponentFunction: templateComponentFunction });

			//if (window.Archives.rollingRender){
			//	this.htmlText = html.replace(/\n/g,'').split('<div class="collection-detailed-row">');
			//}		

			//window.Archives.replaceHtml(this.$el[0],html);
			this.$el.html('One Moment Please...');

			window.setTimeout(function(){

				self.$el.html(html);

				//update the location of the series/subseries headers
				Archives.eventAgg.trigger("global:containerListChanged");
				


			},500);

			*/
			



		}



	






	});

}).call(this);