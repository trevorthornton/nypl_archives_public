/*	NYPL Archives Platform
//	
//	data.js
//
//	Controls the data processing of the series and compoenents
//	
//
*/


(function() {

  "use strict";

	window.Archives.data = {




		//the number of components loaded
		componentsLoded: 0,

		//number of C1, C2 elements
		componentsTotalC1: 0,
		componentsTotalC2: 0,

		//the series component ids
		seriesIds: null,

		seriesAndSubseriesIds : [],

		//the holding pen for HTML to be inserted into the dom when using group rendering
		groupRenderingHTML: '',

		//the array of block doms holding the groups of compoennts
		allGroupBlocks : null,

		//keeps track of what block we are using at the moment
		allGroupBlocksCounter : 0,

		//a timer to control the inserts into the dom
		allGroupBlocksTimer : null,

		//the dom to render 
		allGroupBlocksQueue : [],

		//the number of blocks the system has rendered out
		allGroupBlocksCount : 0,

		//component was not downloaded or something else is messed up, flag it and make sure the final bit of the container list gets rendered
		downloadError: false,

		currentlyDownloadingSeries: 0,

		currentlyRenderingComponent: -1,

		domInsertComplete: false,








		//the base string to build regex that removes HTML tags from the components, it can be configured in the config model
		removeHtmlTagsRegex: "<(?!(~REPLACE~)\\s*\\/?)[^>]+>",


		initalize : function(){

			var self = this;

			//this.removeHtmlTagsRegex = new RegExp("^" + string_to_replace);

			//we need to build the regex that restricts certain html tags from the text of components
			var _replaceString = '';

			if (Archives.a('allowableHTMLTags').length > 0){
				_.each(Archives.a('allowableHTMLTags'), function(e,i){
					_replaceString += e + '|' + '\\/' + e + '|';
				});

				_replaceString = _replaceString.substring(0,_replaceString.length-1);

			}else{
				_replaceString = "NONE";
			}


			this.removeHtmlTagsRegex = this.removeHtmlTagsRegex.replace('~REPLACE~',_replaceString);

			this.removeHtmlTagsRegex = new RegExp(this.removeHtmlTagsRegex, "ig");

			if (!Archives.collectionResponse.component_layout_id){
				Archives.collectionResponse.component_layout_id = 1;
			}


			//register with ask the local data variables
			_.each(this, function(e,i){
				if (typeof e !== 'function'){
					Archives.ask.set(i, function(){return self[i];});
				}
			});

			//store this locally so we don't have to ask 10 thousand times
			this.removeFields = Archives.a('removeFields');


			Archives.eventAgg.on("network:allDownloadsComplete",this.checkComponentCount, this);

			Archives.eventAgg.on("data:domInsertComplete", function(){

				self.checkBuildOwnNav();
				self.domInsertComplete = true;
				Archives.navSide.changingSeries(false);

			}, this);

			


		},



		/*
		//Formats the series into the backbone model and cleans up the data a little
		*/
	    buildSeriesCollection: function(){

			var self = this;
			var seriesArray = [];

			//Where we process the embeded JS into the model 
			_.each(Archives.collectionStructure['components'], function(element, index, list){

				//clean up and series/subseries miss labeling, its only goes 3 deep
				_.each(element.components, function(subseries){
					if (subseries.level_text === 'series'){subseries.level_text = 'subseries';}
						_.each(subseries.components, function(subsubseries){
							if (subsubseries.level_text === 'series'){subsubseries.level_text = 'subseries';}
								_.each(subsubseries.components, function(subsubsubseries){
									if (subsubsubseries.level_text === 'series'){subsubsubseries.level_text = 'subseries';}
								});
						});
				});


				//store the previous series ID, it will be useful when loading compoenet data, to see if 
				seriesArray.push(element);


				if (Archives.debug)
					console.log(element);


				//if we are doing single series render and this is the inital load, mark the first series as the one to render.
				if (Archives.a('renderMode') === 'series'){
					if (Archives.a('activeSeries') === 0 ){
						Archives.eventAgg.trigger("nav:activeSeriesChange",element.id);
					}
				}

			});

			if (Archives.collectionStructure.components){
				this.extractSeriesAndSubseriesIds(Archives.collectionStructure.components);
			}

			Archives.allSeries = new window.Archives.Collections.SeriesCollection(seriesArray);


	    },




		/*
		/   Called after the xhr request is done, loads the response into the component lookup object and also
		/   checks to see if the series is complete, if so mark it as ready to render.
		*/
		processComponetPage: function(data, page){

			if (Archives.debugVerbose)
				console.log("processComponetPage()");

			var self = this;

			var templateFunction = _.template(Archives.templates['singleComponent'][Archives.collectionResponse.component_layout_id]);

			if (Archives.a('renderMode') == 'series'){
				self.seriesIds = _.map(Archives.allSeries.models, function(num){ return num.attributes.id; });
			}


			for (var x = 0; x <= data.page.length -1; x++){
				var element = data.page[x];
				self.processElement(element,templateFunction);
			}

			



			if (Archives.a('renderMode') == 'series'){
				//if this was the last page then the loading is done, mark them all ready
				if (Archives.network.componentPages === page){
					_.each(window.Archives.allSeries.models, function(element, index, list){
						if (!element.get("ready")){
							element.set("ready", true);
						}
					});

				}
			}

			self.updateProcessProgress();

		},




		processElement: function(element,templateFunction){


			var self = this;

			var hasInternalLink = false;

			++self.componentsLoded;

			//data clean up, might need to exapnd if it gets more complicated

			//sometimes collections are marked up using series only, so a series inside a series is marked as a series
			//this may be technically okay, but it is bad for the system, so redfine it as a subseries
			if (element.level_text === 'series' && element.level_num !== 1){
				element.level_text = 'subseries';
			}


			//drop out some unused fields to save a little space
			for (var x = 0; x < this.removeFields.length; x++){
				delete element[this.removeFields[x]];
			}

			//store the component
			Archives.components[String(element.id)] = element;


			if (element.level_num === 1){
				self.componentsTotalC1++;
			}
			if (element.level_num === 2){
				self.componentsTotalC2++;
			}

			if (element.image){
				Archives.ask.set('hasDigitalObject',true);
			}
			if (element.controlaccess){
				Archives.ask.set('hasControledTerms',true)
			}

			if (element.container){
				if (element.container[0]){
					if (element.container[0].type === "internal_collection_link"){
						hasInternalLink = true;
					}
				}
			}


			//SERIES RENDERING MODE --------------------------------

			//the problem with the initial series render is that we do not know what components belong to what series from the inital structure download
			//so we are rendering it differently based on the inital load and subsequent series switching  


			if (Archives.a('renderMode') == 'series'){
				//is the ID of the compoenent we just loaded the id of the series, if so then the previous series is all loaded
				if (_.indexOf(self.seriesIds, element.id) > 0){
					//we are into the next series, so mark the previous series as finished.
					window.Archives.allSeries.get(self.seriesIds[_.indexOf(self.seriesIds, element.id)-1]).set("ready", true);

					//also mark the current one as what wer are downloading
					self.currentlyDownloadingSeries = element.id;

					
				}else if (_.indexOf(self.seriesIds, element.id) === 0){
					self.currentlyDownloadingSeries = element.id;

				}


				//if we are downloading and in the series that is active, start building the data
				if (this.currentlyDownloadingSeries === Archives.a('activeSeries') && this.allGroupBlocksTimer === null){
					this.startRenderQueue();
				}

				if (this.currentlyDownloadingSeries !== Archives.a('activeSeries')){
					//render the leftover html
					if (this.groupRenderingHTML !== ''){
						this.allGroupBlocksQueue.push({dom: null, html: this.groupRenderingHTML, id: element.id});
						this.groupRenderingHTML = '';
					}

					this.turnOffQueue = true;
				}


				if (this.currentlyDownloadingSeries === Archives.a('activeSeries')){

					if (this.componentsLoded  % Archives.a('componentsPerPass') === 0 || this.componentsLoded === Archives.a('componentCount')){

						//render 
						//push a container out there to hold it
						this.groupRenderingHTML += templateFunction({model: element, renderRow:true});

						this.allGroupBlocksQueue.push({dom: null, html: this.groupRenderingHTML, id: element.id - Archives.a('componentsPerPass')});

						this.allGroupBlocksCounter++;
						this.groupRenderingHTML = '';

					}else{
						this.groupRenderingHTML += templateFunction({model: element, renderRow:true});
					}
				}



			}


			//SKELETON RENDERING MODE (group render)--------------------------------


			if (Archives.a('renderMode') == 'skeleton'){


				//this renders blocks to the page in X number of components, configurable in the config model
				if (Archives.a('useGroupingRender')){


					//make sure the vars are initilzed 
					if (this.allGroupBlocks === null){
						this.allGroupBlocks = $(".collection-detailed-block");

						this.startRenderQueue();

					}


					//do we render or do we store the hmtl hlmt html
					if (this.componentsLoded  % Archives.a('componentsPerPass') === 0 || this.componentsLoded === Archives.a('componentCount')){

						//render 
						//this.replaceHtml(this.allGroupBlocks[this.allGroupBlocksCounter], this.groupRenderingHTML);
						this.groupRenderingHTML += templateFunction({model: element, renderRow:true});

						this.allGroupBlocksQueue.push({dom: this.allGroupBlocks[this.allGroupBlocksCounter], html: this.groupRenderingHTML, id: element.id - Archives.a('componentsPerPass')});

						this.allGroupBlocksCounter++;
						this.groupRenderingHTML = '';

					}else{
						this.groupRenderingHTML += templateFunction({model: element, renderRow:true});
					}



				}else{


					//SKELETON RENDERING MODE (standard render)--------------------------------


					//var dom = $("#c" + element.id);
					var dom = document.getElementById("c" + element.id);

					//does this div exist already for this component? 
					if (dom !== null){

							try{

									if (Archives.a('requestAnimationFrame') !== null){


										Archives.a('requestAnimationFrame').call(window, function(){


											Archives.data.replaceHtml(dom, templateFunction({model: element}));


										})

									}else{


										Archives.data.replaceHtml(dom, templateFunction({model: element}));


									}


							}catch (err){

								//TODO something goes wrong here for /the/21808
								if (self.debug)
									console.error(dom);

								console.error("Error on dom insert", err);


							}



					}else{


						//this should happen rarely, not opptimized
						if (Archives.debug) console.log(element.id,"Does not exist");

						$("#collection-content-detailed").append(templateFunction({model: element, renderRow:true})); 

	
					}

				}

			}




	    },

	    updateProcessProgress: function(){

			var self = this;

			if (this.debugVerbose)
				console.log("updateProcessProgress()");   


			var percent = Math.round(this.componentsLoded / Archives.componentCount * 100);


			Archives.eventAgg.trigger('data:pageProcessed', percent);


			if (percent === 100){


				Archives.eventAgg.trigger('data:pageLoaded', percent);
				Archives.ask.set('pageLoaded',true);


				//ready last series 
				if (Archives.a('renderMode') == 'series'){
					Archives.allSeries.models[Archives.allSeries.models.length-1].set("ready", true);
				}




				if (this.componentsTotalC1 < this.minNumberOfC1)
					Archives.eventAgg.trigger("navSide:hide");



				
				Archives.eventAgg.trigger('global:containerListChanged');



			}




		},


		checkBuildOwnNav : function(){

				//are there no series, meaning that none were defined?
				if (Archives.allSeries.length === 0)
					Archives.ask.set('buildOwnNav',true);


				//do we want to build our own navigation?
				if (Archives.a('buildOwnNav') && this.componentsTotalC1 <= Archives.a('maxNumberOfC1') && this.componentsTotalC1 >= Archives.a('minNumberOfC1') && this.componentsLoded >= Archives.a('minNumberOfCTotal')){

					if (Archives.debug)
						console.log("Building Custom Nav");

					Archives.navSide.buildCustomNav();

					//assign it over to the system wide structure var
					Archives.collectionStructure = Archives.navSide.builtNav;

					this.buildSeriesCollection();

					//build the series collection to help with navigation
					Archives.navSide.render();
				}

		},

		//this is a final check to see if the number of components we thought were coming down actually showed up, if now push out whatever is left in the render qqueue
		checkComponentCount : function(){


			if (Archives.a('componentCount') !== this.componentsLoded){
				this.allGroupBlocksQueue.push({dom: this.allGroupBlocks[this.allGroupBlocksCounter], html: this.groupRenderingHTML});
				this.allGroupBlocksCounter++;
				this.groupRenderingHTML = '';
			}

			this.turnOffQueue = true;




		},


		//check the dom vs the object and makesure everything lines up
		//looks at parent_id of the data model and then looks at the series, subseries, and indent-width-x css classes to see if the component looks like it belongs to the right parent.
		validateStructure : function(){


			var all = $("#collection-content-detailed .collection-detailed-row");
			var activeSeries = 0, activeSubSeries = 0;
			var levels = {};
			var errorFree = true;

			for (var x = 0; x < all.length; x++){

				var id = parseInt( all[x].id.replace('c','') );

				if (all[x].className.search('margin-series') > -1) activeSeries = id;
				if (all[x].className.search('margin-subseries') > -1) activeSubSeries = id;

				var currentLevel = 0;

				if (all[x].childNodes){
					if (all[x].childNodes[0]){

						if (all[x].childNodes[0].className){



							var classes = all[x].childNodes[0].className.split(' ');
							for (var y = 0; y < classes.length; y++){
								
								if (classes[y].search('indent-width-') > -1){
									currentLevel = classes[y][classes[y].length-1];
									levels[currentLevel] = id;


								}


							}
						}

					}
				}

				if (Archives.components[id].parent_id){
					if (Archives.components[id].parent_id !== activeSeries && Archives.components[id].parent_id !== activeSubSeries){
						if (currentLevel - 1 > 1){
							if (levels[currentLevel-1] !== Archives.components[id].parent_id){
								console.error("The finding aid structure is misaligned from the data model");
								console.error(Archives.components[id]);
								console.error("data model: I'm component",id, " my parent is", Archives.components[id].parent_id);
								console.error("current series = ", activeSeries );
								console.error("current sub-series = ", activeSubSeries );
								console.error("levels",levels);
								console.error($("#c"+id));
								console.error("------------------------------");
								errorFree = false;
							}
						}
					}
				}
				
			}




			return errorFree;

		},


		startRenderQueue : function(){

			var self = this;

			//start the render queue
			this.allGroupBlocksTimer = window.setInterval(function(){



				if (self.allGroupBlocksQueue.length !== 0){

					//do we need to build our own dom?	
					var addOwnDom = false;

					if (typeof Archives.data.allGroupBlocksQueue[0].dom  === 'undefined')
						addOwnDom = true;

					if (Archives.data.allGroupBlocksQueue[0].dom === null)
						addOwnDom = true;

					if (addOwnDom){
						var dom = $("<div>").addClass('collection-detailed-block');
						$("#collection-content-detailed").append(dom);
						Archives.data.allGroupBlocksQueue[0].dom = dom.get(0);

					}



					self.allGroupBlocksCount++;

				
					if (Archives.a('requestAnimationFrame') !== null){
						Archives.a('requestAnimationFrame').call(window, function(){

							Archives.data.replaceHtml(Archives.data.allGroupBlocksQueue[0].dom, Archives.data.allGroupBlocksQueue[0].html);

							//update the system with the last component that we just rendrered
							if (Archives.data.allGroupBlocksQueue[0].id){
								self.currentlyRenderingComponent = Archives.data.allGroupBlocksQueue[0].id;
							}


							self.allGroupBlocksQueue.splice(0,1);
		


						});

					}else{

						self.replaceHtml(self.allGroupBlocksQueue[0].dom, self.allGroupBlocksQueue[0].html);


						//update the system with the last component that we just rendrered
						if (Archives.data.allGroupBlocksQueue[0].id){
							self.currentlyRenderingComponent = Archives.data.allGroupBlocksQueue[0].id;
						}


						self.allGroupBlocksQueue.splice(0,1);



					}
					

					



				}else{

					if (self.turnOffQueue){
						window.clearInterval(self.allGroupBlocksTimer);
						self.validateStructure();



						Archives.eventAgg.trigger('data:domInsertComplete');
						Archives.eventAgg.trigger("global:containerListChanged");

					}


				}

			}, Archives.a('componentsPassDelay'));

		},


		//Turns on and off the render queue when we are switching bewtween series
		seriesChangeRender : function(id){

			var staticCounter = 0;

			var templateFunction = _.template(Archives.templates['singleComponent'][Archives.collectionResponse.component_layout_id]);


			this.allGroupBlocks = $(".collection-detailed-block");
			this.allGroupBlocksCounter = 0;
			this.turnOffQueue = false;

			this.domInsertComplete = false;

			this.startRenderQueue();

			var renderCount = 0;


			//loop through all of the components that should numerically belong to this series
			for (var x = id; x < id + Archives.allSeries.get(id).get('total_components')+1; x++){



				if (Archives.components[x]){


					if (!Archives.components[x].top_component_id && Archives.components[x].parent_id){
						Archives.components[x].top_component_id = Archives.components[Archives.components[x].parent_id].top_component_id;
					}



					if (Archives.components[x].top_component_id === id || Archives.components[x].id === id){


						//do we render or do we store the hmtl hlmt html
						if ((staticCounter % Archives.a('componentsPerPass') === 0 || staticCounter === Archives.allSeries.get(id).get('total_components')) && staticCounter !== 0){


							//render 
							this.groupRenderingHTML += templateFunction({model: Archives.components[x],renderRow:true});
							this.allGroupBlocksQueue.push({dom: this.allGroupBlocks[this.allGroupBlocksCounter], html: this.groupRenderingHTML, id: Archives.components[x].id - Archives.a('componentsPerPass')});

							this.allGroupBlocksCounter++;
							this.groupRenderingHTML = '';

						}else{
							this.groupRenderingHTML += templateFunction({model: Archives.components[x],renderRow:true});
						}


					}else{

						console.error("Trying to render", x, Archives.components[x], "but Archives.components[x].top_component_id =", Archives.components[x].top_component_id, " and id =", id, ' or Archives.components[x].id = ', Archives.components[x].id , 'and id =',id);

					}

				}else{

					console.error("Trying to render", x, Archives.components[x], "but was undefined" );

				}

				staticCounter++;

			}

			//push out any leftovers
			if (this.groupRenderingHTML!== ''){
				this.allGroupBlocksQueue.push({dom: this.allGroupBlocks[this.allGroupBlocksCounter], html: this.groupRenderingHTML, id: x});
				this.groupRenderingHTML = '';
			}

			this.turnOffQueue = true;




		},

		//stops the rendering
		cancel: function(){

			this.allGroupBlocksQueue = [];
			this.turnOffQueue = true;


		},


		replaceHtml: function (el, html) {

			//var oldEl = typeof el === "string" ? document.getElementById(el) : el;
			/*@ccOn // Pure innerHTML is slightly faster in IE
				el.innerHTML = html;
				return el;
			@*/
			var newEl = el.cloneNode(false);
			newEl.innerHTML = html;

			el.parentNode.replaceChild(newEl, el);
			/* Since we just removed the old element from the DOM, return a reference
			to the new element, which can be used to restore variable references. */


			return newEl;
		},


		//We need to know what the series ids are because we make some guesses about what are valid c#### ids are. so do not add one that will be rendered 
		extractSeriesAndSubseriesIds : function (tree) {


			for (var i = 0; i < tree.length; i++) {

				this.seriesAndSubseriesIds.push(tree[i].id);

		        if(tree[i].components){
					this.extractSeriesAndSubseriesIds(tree[i].components);
				}

			}
		},

		removeHtmlTags : function(text){

			//if we are not doing it dont do it.
			if (!Archives.a('removeHTLMTags')){return text;}

			//whoops this is striping out my serch hilghliting, figure something out....
			if (text.search("search-highlight") !== -1){return text;}

			return text.replace(this.removeHtmlTagsRegex, "");

		}






	}

}).call(this);