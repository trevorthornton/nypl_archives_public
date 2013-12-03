/*	NYPL Archives Platform
//	
//	view_nav_filter.js
//
//	This view controls the displaying of digital assets
//	The trigger to preview digital assets (hover) is taken care of in the window view to allow event delegation
//
*/

(function() {

	"use strict";


	window.Archives.Views.navFilter = Backbone.View.extend({



		events: {
			'submit form' : 'searchSubmit',
			'click #nav-filter-clear a' : 'isNotFiltered',
			'focus #nav-filter-form input' : 'showTip',
			'blur #nav-filter-form input' : 'hideTip'
		},


		initialize: function(){

			Archives.eventAgg.on('navFilter:searchError', this.searchError, this);
			Archives.eventAgg.on('navFilter:isFiltered', this.isFiltered, this);


			//register it with ask (the data bit is stored in the module)
			Archives.ask.set('isFiltered',function(){return Archives.filter.isFiltered;});


			$("#nav-filter-form input").first().tooltip(
				{
					placement: function(){ return  (Archives.allSeries.length===0) ? "bottom" : "top";},
					trigger: "manual",
					html: true,
					title : "Filter by keyword such as 'Franklin' <br> or dates such as '1775' <br>or range '1775-1783'"
				}
			);



		},


		showTip: function(){

			$("#nav-filter-form input").tooltip('show');

		},

		hideTip: function(){

			$("#nav-filter-form input").tooltip('hide');

		},


		render: function() {

			


		},

		isNotFiltered: function(e){



			$("#nav-filter-clear a").hide();
			//$("#nav-detailed-list").css('visibility','visible');
			$('#fixed-nav-title').text('');

			$("#collection-content-detailed").fadeIn("fast");
			$("#collection-content-searchresults").fadeOut();
			$("#collection-content-searchresults").html('');

			$("#nav-filter-form input").val('');

			Archives.filter.isFiltered = false;

			Archives.navSide.render();

			Archives.eventAgg.trigger('global:containerListChanged');

			Archives.eventAgg.trigger('navFilter:isNotFiltered');

			e.preventDefault();
			return false;
		},


		isFiltered: function(){

			this.hideTip();

			$("#nav-filter-clear a").show();
			$('#nav-title-holder').css('visibility','visible');
			



		},





		searchSubmit: function(e){

			if (Archives.debug)
				console.log("Searching: ", $("#nav-filter-form input").val());

			Archives.filter.searchData($("#nav-filter-form input").val());
			e.preventDefault;
			return false;


		},

		searchError: function(msg){

			$("#nav-filter-no-results").text(msg).fadeIn("fast",function(){
	          $("#nav-filter-no-results").fadeOut(3000);
	        });    



		}





	});

}).call(this);