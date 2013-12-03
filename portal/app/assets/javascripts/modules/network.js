
/*	NYPL Archives Platform
//	
//	network.js
//
//	Controls the network communication downloading the componenets
//	
//
*/


(function() {

	"use strict";


	window.Archives.network = {


		//these are explained and defined in the config model
		componentPageSize : null,
		componentLoadAsync : null,
		xhrErrorLimit : null,
		xhrRequestRate: null,
		xhrTimeout : null,



		//this number of pages in this collection
		componentPages: 0,

		//number of pages completely downloaded     
		componentPagesDownloaded: 0,

		//the current page we are trying to download.
		compoenetPagesActive: 0,

		//keep track the number of network errors we run into, to see if something big is going wrong conectivitly wise
		xhrErrorCount: 0,




		downloadComponents: function(){

			var self = this;



			//load in the settings from the config model
			this.componentPageSize  = Archives.a('componentPageSize');
			this.componentLoadAsync = Archives.a('componentLoadAsync');
			this.xhrErrorLimit = Archives.a('xhrErrorLimit');
			this.xhrRequestRate = Archives.a('xhrRequestRate');
			this.xhrTimeout  = Archives.a('xhrTimeout');


			//register these vars with ask
			Archives.ask.set('componentPages',function(){return self.componentPages;});
			Archives.ask.set('componentPagesDownloaded',function(){return self.componentPagesDownloaded;});
			Archives.ask.set('compoenetPagesActive',function(){return self.compoenetPagesActive;});
			Archives.ask.set('xhrErrorCount',function(){return self.xhrErrorCount;});



			//calc how many pages in this collection
			//load the compoents from the server, bump up if there is remainder
			this.componentPages = (Math.floor(Archives.componentCount/this.componentPageSize)) + ((Archives.componentCount % this.componentPageSize) ? 1 : 0);

			if (Archives.debug) console.log("Components:",Archives.componentCount, "Pages: ", this.componentPages);

			if (this.componentLoadAsync){

				_.each(_.range(this.componentPages), function(element, index, list){
					//this is an attempt to space out the requests, allow for some processing, so we don't lock things up
					window.setTimeout(function(){

						self.requestComponentPage(element);

					}, self.xhrRequestRate * element);
				});



			}else{

				this.requestComponentPage(this.compoenetPagesActive);

			}



		},



		requestComponentPage: function(page){

			var self = this;

			if (Archives.debug)
				console.log("requestComponentPage()", page);



			var request = $.ajax({
				url: "/collection/"+Archives.collectionId+"/container_list/" + page,
				type: "GET",
				dataType: "json",
				timeout: self.xhrTimeout
			});

			request.always(function(data) { 

				if (this.debug)
					console.log(request.status, request.statusText, request.readyState);

				//chrome is doing some weird stuff right now...
				if (request.status===200){


					++self.compoenetPagesActive;


					Archives.data.processComponetPage(data, page);
					
					self.componentPagesDownloaded++;

				
					Archives.eventAgg.trigger('network:downloadedComponentPage');


					if (!this.componentLoadAsync && self.compoenetPagesActive < self.componentPages){

						self.requestComponentPage(self.compoenetPagesActive);

					}


					if (self.componentPages === self.componentPagesDownloaded){
						Archives.eventAgg.trigger('network:allDownloadsComplete');
					}


				}else{


					++self.xhrErrorCount;

					if (Archives.debug)
						console.error("Error Count #", self.xhrErrorCount, "xhr Request failed to: ", this.url, request.status, request.statusText);


					Archives.eventAgg.trigger('network:downloadedComponentPageError');

					//try this request again if we are below the threshold
					if (self.xhrErrorCount <= self.xhrErrorLimit){
						self.requestComponentPage(self.compoenetPagesActive);
					}else{
						Archives.eventAgg.trigger('network:downloadedComponentPageErrorFatal');
					}

				}

				


			});





		}




	};

}).call(this);