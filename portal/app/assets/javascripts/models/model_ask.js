/*	NYPL Archives Platform
//	
//	model_ask.js
//
//	This model serves as a avenue to update parts of the system with current conditions and configurations
//	
//
*/

(function() {

	"use strict";


	window.Archives.Models.Ask = Backbone.Model.extend({


		defaults: {

			//something really bad happend
			globalError : false,

			//the active series being displayed if we are in series mode rendering
			activeSeries : 0,

			activeSubSeries : 0,

			//is something happening that should prevent other major actions from taking place?
			blockingAction : false,

			//are we on the details page/container list
			onDetailPage: false,

			//does this collections have controled terms attached?
			//is detected in the data module when processing the components
			hasControledTerms : false,

			//does this collection have digital assets attached?
			//is detected in the data module when processing the components
			hasDigitalObject : false,



			//some system properties
			hasKeys : (Object.keys) ? true : false,
			hasOwn : (Object.hasOwnProperty) ? true : false,
			requestAnimationFrame: window.requestAnimationFrame || window.mozRequestAnimationFrame ||window.webkitRequestAnimationFrame || window.msRequestAnimationFrame || null,



		},

			initialize: function(){

			var self = this;

			//leak a little into the Archives namespace for shorter code
			Archives.a = function(index){return self.val(index);};

			//set the browser variable
			this.browserDetect();

			

			//register these components with ask
			_.each(this.defaults, function(e,i){
				self.set(i, function(){return self.defaults[i];});
			});


			//listens for things

			//the network module will throw this event when it tried x times and failed to download component page
			Archives.eventAgg.on("network:downloadedComponentPageErrorFatal", function(){self.set('globalError',true);});


			//the active series is the current series that is displaying for the user, can be triggred from a number of sources
			Archives.eventAgg.on("nav:activeSeriesChange", function(data){
				self.set('activeSeries',data); 
			});

			Archives.eventAgg.on('data:domInsertComplete', function(){
				self.set('blockingAction',false);
			});




			this.on("change:activeSeries", function(){
				Archives.eventAgg.trigger("global:seriesChange");
			});

			//ALL events in the app are here

			//when the container list changes
			Archives.eventAgg.on("global:containerListChanged", function(){});




			//when one page was processed
			Archives.eventAgg.on('data:pageProcessed',  function(){});

			//when the page of components was downloaded from the server
			Archives.eventAgg.on('data:pageLoaded',  function(){});

			//fired after the dom has been updated, last step
			Archives.eventAgg.on('data:domInsertComplete',  function(){});




			//all of the downloading is done
			Archives.eventAgg.on('network:allDownloadsComplete',  function(){});

			//there was a single occurnace of an error
			Archives.eventAgg.on('network:downloadedComponentPageError',  function(){});



			//Hide the left side navigation 
			Archives.eventAgg.on("navSide:hide",  function(){});

		},

		//this is the proper function that retuns the value of a registered property based on passed name
		//Archives.a() is an alias, defined in intialization above
		val : function(index){

			//some data lives in the model/modules but some data has not place to live except here, so sometimes it is not a reference to some data somewhere but the literal.

			if (typeof this.get(index) === 'function'){
				return this.get(index)();
			}else{
				return this.get(index);
			}
		},


		//sets the browser object, based on jquery 
		browserDetect: function(){

			var ua = navigator.userAgent.toLowerCase();
			var browser = {};
			var self = this;

			var match = /(chrome)[ \/]([\w.]+)/.exec( ua ) ||
			/(webkit)[ \/]([\w.]+)/.exec( ua ) ||
			/(opera)(?:.*version|)[ \/]([\w.]+)/.exec( ua ) ||
			/(msie) ([\w.]+)/.exec( ua ) ||
			ua.indexOf("compatible") < 0 && /(mozilla)(?:.*? rv:([\w.]+)|)/.exec( ua ) ||
			[];

			var matched = {
				browser: match[ 1 ] || "",
				version: match[ 2 ] || "0"
			};

			if ( matched.browser ) {
				browser[ matched.browser ] = true;
				browser.version = matched.version;
			}

			// Chrome is Webkit, but Webkit is also Safari.
			if ( browser.chrome ) {
				browser.webkit = true;
			} else if ( browser.webkit ) {
				browser.safari = true;
			}

			this.browser = browser;
			this.set('browser', function(){return browser;});
		}


		/*
		set: function(key, value, options) {

			if (_.isObject(key) || key == null) {
				var attrs = key;
				var options = value;
			} else {
				var attrs = {};
				attrs[key] = value;
			}

			//make sure this is not yet taken in our little namespace
			console.log('setting',key);


			return Backbone.Model.prototype.set.call(this, attrs, options);
		}
		*/


	});


	

}).call(this);