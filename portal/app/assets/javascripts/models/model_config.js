/*	NYPL Archives Platform
//	
//	model_config.js
//
//	This model stores and sets the configuration options of the client
//	
//
*/

(function() {

	"use strict";

	window.Archives.Models.Config = Backbone.Model.extend({


		defaults: {


		//------------------------------
		//Config for component processing

			//should we remove tags from the compoenent's text? 
			removeHTLMTags : false,
			
			//What html tags can appear in the compoent texts, scopenote biohist, etc... All others will be striped out if turned on
			allowableHTMLTags : ['p','br'],

			//how many c01 elements can exist total and still try and build a custom nav is needed (this is to prevent building nav for 1000 c01 finding aids)
			maxNumberOfC1: 22,

			//the min number of c01 elements there need to be to build navigatation if needed, to prevent 1 series useless nav
			minNumberOfC1: 2,

			//how many total components does there need to be to initalize custome nav building, to prevent building nav for tiny collections
			minNumberOfCTotal: 50,

			//these are the fields that are not needed so remove them from the json object
			removeFields : [
			"collection_id",
			"created_at",
			"identifier_type",
			"identifier_value",
			"max_depth",
			"org_unit_code",
			"org_unit_id",
			"org_unit_name",
			"org_unit_name_short",
			"sib_seq",
			"type",
			"updated_at"
			],

		//------------------------------

		//------------------------------
		//Config for downloading components
			
			//how many components it should download per request, you must change this in the server controler as well
			componentPageSize: 2000,

			//how to load the component data, snyc or async
			componentLoadAsync: false,

			//number of milliseconds between each page of components request (if doing async)
			xhrRequestRate: 500,

			//max number of errors until it gives fatal could not load components error
			xhrErrorLimit: 10,

			//the wait time for xhr Requests before they timeout
			xhrTimeout: 10000,

		//------------------------------

		//------------------------------
		//Config for performance


			//default render mode. Can be 'series'
			renderMode : 'skeleton',

			//if it meets criteria it will build its own nav hierarchy
			buildOwnNav : false,

			//what is the max number of components until we switch over to series rendering
			maxComponentsForSkeletonRender: 10000,

			//max number of components for inernet explorer to render in skeleton mode
			maxComponentsForSkeletonRenderIE: 5000,

			maxComponentsForSkeletonRenderBergLayout: 5000,

			//grouping render inserts X number of components into the page at once, it is to find a balance between updating the dom and responsivness
			useGroupingRender : true,

			//the number of components to render per pass in skeleton mode
			componentsPerPass : 1000,

			//the number of milliseconds to wait inbetween inserting the dom group		
			componentsPassDelay: 250,




		//------------------------------


		//------------------------------
		//Config for display

			//the number of charaters to crop the series and subseries description
			trucatePopoverTextAt : 750,


		//------------------------------



		},

		initialize: function(){
			var self = this;


			//process the performance info
			if (Archives.a('componentCount') > this.defaults.maxComponentsForSkeletonRender){
				this.defaults.renderMode = 'series';
			}else{
				this.defaults.renderMode = 'skeleton';
			}

			if (Archives.a('browser').msie){
				if (Archives.a('componentCount') > this.defaults.maxComponentsForSkeletonRenderIE){
					this.defaults.renderMode = 'series';
				}else{
					this.defaults.renderMode = 'skeleton';
				}
			}

			if (Archives.collectionResponse.component_layout_id){
				if (Archives.collectionResponse.component_layout_id == 2 && Archives.a('componentCount') > this.defaults.maxComponentsForSkeletonRenderBergLayout)
					this.defaults.renderMode = 'series';
			}


			//build nav if there is no collection structure
			if (!Archives.collectionStructure.components){
				this.defaults.buildOwnNav = true;
			}



			//register these components with ask
			_.each(this.defaults, function(e,i){
				Archives.ask.set(i, function(){return self.defaults[i];});
			});

		}




	});

}).call(this);