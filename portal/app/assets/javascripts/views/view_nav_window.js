/*	NYPL Archives Platform
//	
//	view_nav_window.js
//
//	This view controls the larger window events such scrolling and resizing
//	A central place to dispach events
//
*/

(function() {

	"use strict";

	window.Archives.Views.navWindow = Backbone.View.extend({


		scrollTimeout: null,

		mousemoveTimeout: null,

		keyBuffer: '',

		showPermLinks: false,

		aDigitalAssetMouseoverEvent : null,

		aDigitalAssetMouseoverIsSet : false,

		aDigitalAssetMouseoverIsShowing : false,

		events: {

			'keyup'	: 'keyup',
			'click' : 'click',
			'mousemove' : 'mousemove'


		},


		initialize: function(){

			var self = this;

			Archives.eventAgg.on('global:containerListChanged',function(){
				window.setTimeout(function(){self.resize();},250);
			});


			//gloabl scroll handler
			var scroll = _.throttle(self.doScroll, 250);
			this.$el.scroll(scroll);


			var resize = _.throttle(self.resize, 300);
			this.$el.resize(resize);





		},



		render: function() {



		},


		click : function(e){


			if (Archives.a('hasDigitalObject')){


				var $target = $(e.target);	


				if (e.target.className === "asset-link" || e.target.className === "icon-film" || e.target.className === 'container-abrv' || e.target.className === 'asset-preview' || e.target.className === 'asset-preview-div'){


					if (e.target.className === "asset-link"){
						var c = window.Archives.components[$target.parent().parent().parent().attr("id").replace("c","")];

					}else if (e.target.className === 'asset-preview'){

						//this is the acutal preview, it works on mobile devices
						var c = window.Archives.components[$target.parent().parent().parent().parent().parent().parent().parent().attr("id").replace("c","")];

					}else if (e.target.className === 'asset-preview-div'){

						//this is the acutal preview, it works on mobile devices
						var c = window.Archives.components[$target.parent().parent().parent().parent().parent().parent().attr("id").replace("c","")];



					}else{


						var c = window.Archives.components[$target.parent().parent().parent().parent().attr("id").replace("c","")];
					}



					Archives.digitalAssets.launchLightbox(this.aDigitalAssetMouseoverEvent,c);



					e.preventDefault;
					return false;

				}
			

			}


		},


		mousemove: function(e){




			var self = this;

			if (Archives.a('hasDigitalObject')){

				if (!this.aDigitalAssetMouseoverIsShowing){

											

					if (e.target.className === "asset-link" || e.target.className === "icon-film" || e.target.className === 'container-abrv'){


						if (e.target.className === "asset-link"){
							var $target = $(e.target);	
						}else{
							var $target = $(e.target).parent();	
						}

						var c = window.Archives.components[$target.parent().parent().parent().attr("id").replace("c","")];


						this.aDigitalAssetMouseoverIsShowing = true;


						Archives.digitalAssets.previewAssetShow($target,c);
						this.aDigitalAssetMouseoverEvent = $target;

						if (!this.aDigitalAssetMouseoverIsSet){

							self.aDigitalAssetMouseoverIsSet = true;


							this.aDigitalAssetMouseoverEvent.on("mouseleave",function(){

								self.aDigitalAssetMouseoverEvent.unbind();

								Archives.digitalAssets.previewAssetHide($target);
								self.aDigitalAssetMouseoverIsSet = false;
								self.aDigitalAssetMouseoverIsShowing = false;

							});
						}


					}

				}


			}



			if (!this.showPermLinks) return false;

			window.clearTimeout(this.mousemoveTimeout);

			this.mousemoveTimeout = window.setTimeout(function(){

				var element = $(e.target);

				if (element.parent().hasClass('collection-detailed-row')) element = $(element.parent());
				if (element.parent().parent().hasClass('collection-detailed-row')) element = $(element.parent().parent());

				if (element.hasClass('collection-detailed-row')){

					element.css("background-color","rgb(252, 252, 252)").css("position","relative");

					

					element.append(

						$("<a>")
							.css("position",'absolute')
							.attr("class","permlink")
							.css("display","block")
							.css("top","0px")
							.css("right","0px")
							.css("font-family",'icomoon')
							.css("color","#3f3a34")
							.css("font-size","24px")
							.css("margin","2px")
							.attr("title","Permanent Link")
							.attr("alt","Permanent Link")
							.text("s")
							.attr("href", window.location.origin + window.location.pathname + "#" + element.attr("id"))


					)


					element.mouseleave(function(){

						$(this).css("background-color","whitesmoke").css("position","static");;

						$(".permlink").remove();

						$(this).unbind();
					})

				}

				


			},75);



		},


		doScroll: function(){
			Archives.navSticky.checkStickyPositions();
			Archives.eventAgg.trigger("global:scrolling");
		},


		resize: function(){
			Archives.eventAgg.trigger("global:resize");
		},

		keyup: function(e){


		  if (e.keyCode == 27) { 

		  	if (Archives.a('isFiltered')){	


		  		//dont clear on esc if the viewer is open
		  		if (Archives.a('viewerOpen')){
		  			Archives.digitalAssets.colorBoxObj.colorbox.close()
		  		}else{
					Archives.eventAgg.trigger('navFilter:isNotFiltered',e);
		  		}


		  	}
		  }   // esc


		  //temp/network/thing
		  this.keyBuffer  += String.fromCharCode(e.keyCode).toLowerCase();
		  if (this.keyBuffer.search('networksarecool') !== -1){
		  	this.keyBuffer = '';
		  	Archives.viz.init();
		  }
		  if (this.keyBuffer.search('showhits') !== -1){
		  	this.keyBuffer = '';
		  	$(".hit-indicator").toggle();

		  }
		  if (this.keyBuffer.search('newpdf') !== -1){
		  	var path = window.location.origin + window.location.pathname + '/newpdf';
		  	window.location = path;

		  }
		  if (this.keyBuffer.search('permlinks') !== -1){
		  	this.keyBuffer = '';		  	
		  	this.showPermLinks = true;
		  }
		  if (this.keyBuffer.search('archivesadmin') !== -1){
		  	this.keyBuffer = '';
		  	Archives.eventAgg.trigger('global:adminLinks',e);
		  }

		}




	});


}).call(this);