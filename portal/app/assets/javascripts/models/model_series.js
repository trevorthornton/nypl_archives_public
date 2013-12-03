
/*	NYPL Archives Platform
//	
//	model_series.js
//
//	This was the orginal method of rendering the finding aid. Wait until the series components were ready and the render the entire series
//	The skeleton rendering system is more responsive for some
//
*/


(function() {

	"use strict";


	window.Archives.Models.Series = Backbone.Model.extend({


		defaults: {
			ready:  false,				//is this series ready/done dowloading the compoenents?
			previousSeriesId: 0,		//holds the previous series id, used to find when the dynamic loading is done for a series
			blockCounter : {count : -1},	//keeps track in the template how many blocks it has rendered
			collectionStructure: null


		},

		initialize: function(){



			//find the collection structure for this series
			if (Archives.collectionStructure.components){

				for ( var x = 0; x < Archives.collectionStructure.components.length; x++){
					if (Archives.collectionStructure.components[x].id){
						if (Archives.collectionStructure.components[x].id === this.id){
							this.set('collectionStructure', Archives.collectionStructure.components[x]);
						}
					}
				}
			}else{
				console.error("Archives.collectionStructure.components expected but not found");
			}



			//Store the view into the series modle
			this.view = new window.Archives.Views.series({model: this, el: $("#collection-content-detailed")});

			
			/*
			if (window.Archives.singleSeriesView || window.Archives.adhocRendering){
				var initalHTML = '';
			}else{
				var initalHTML = "Loading " + this.get("title") + "...";
			}


			//make a container for this series
			$("#collection-content-detailed").append(
				$("<div>")
					.attr("id","collection-content-detailed-" + this.get("id"))
					.addClass("collection-content-detailed-series-container")
					.append(
						$("<span>")
							.html(initalHTML)

					)

			);
			*/




			/*

			this.on("change:ready", function(){



			

				//if we are only rendering one series at a time and it is not this series/model then return
				if (window.Archives.singleSeriesView && this.attributes.id !== window.Archives.singleSeriesRender){
					return false;
				}


				this.view.render();



			});
			*/


		}


	});

}).call(this);