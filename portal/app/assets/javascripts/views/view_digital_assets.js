/*	NYPL Archives Platform
//	
//	viewDigitalAssets.js
//
//	This view controls the displaying of digital assets
//	The trigger to preview digital assets (hover) is taken care of in the window view to allow event delegation
//
*/

(function() {

	"use strict";


	window.Archives.Views.digitalAssets = Backbone.View.extend({


		viewerOpen : false,

		colorBoxObj : null,


		initialize: function() {

			var self = this;

			Archives.ask.set('viewerOpen',function(){return self.viewerOpen;});


		},

		previewAssetHide: function(element){

			element.popover("destroy");

		},

		previewAssetShow: function(element, c){


			if (c.image){
				element.popover({ trigger: "manual", html: "true", content: '<a href="#"><div class="asset-preview-div" style="width:250px; height:210px; text-align:center;"><img class="asset-preview" style="height: 200px; width: auto;" src="http://images.nypl.org/index.php?id=' + c.image[0].image_id + '&t=t"><div class="asset-preview" style="text-align:center; height: 10px;">1/' + c.image.length + ' Images</div></div></a>' });
				element.popover("show");
			}



		},

		launchLightbox: function(element, c){

			self = this;

			//Use post or get?
			var usePost = true;


			//remove the popover
			element.parent().popover("destroy");
			element.popover("destroy");

			if (c.image){
		
				if (usePost){


					//build post object
					var embedDoc = [];

					_.each(c.image, function(image, index, list){
						embedDoc.push(
							{
								uuid: image.uuid, 
								imageID: image.image_id
							});
					});


					var metadata = {};



					//we need to loop through and find the compelete path of this componenet
					
					var lookFor = -1;
					var path = "";
					if (c.parent_id){lookFor = c.parent_id;}

	        		for (var x = 0; x < 10; x++){
	        			
	        			if (lookFor === -1){break;}
	        			path = Archives.components[lookFor].title + ' -- ' + path;   
	        			if (Archives.components[lookFor].parent_id){lookFor = Archives.components[lookFor].parent_id;}else{lookFor = -1;}


	        		}

	        		path = Archives.collectionStructure.title + ' -- '+ path;

	        		path = path.substring(0,path.length-4);

	        		var displayOrigination = '';

					if (c.origination){
						
						_.each(c.origination, function(a) {
						  if (a.value){
						    displayOrigination += a.value.replace('<p>','').replace('</p>','');
						  }
						});

						displayOrigination = displayOrigination;
					}
					var displayExtentStatement = '';

					if (c.extentStatement){
						
						_.each(c.extentStatement, function(a) {
						  if (a.value){
						    displayExtentStatement += a.value.replace('<p>','').replace('</p>','');
						  }
						});

						displayExtentStatement =  displayExtentStatement;
					}

					var displayCitation = "";

					if (Archives.collectionStructure.title){
						displayCitation = displayCitation + 	Archives.collectionStructure.title;					
					}
					if (Archives.components[1]){
						if (Archives.components[1].orgUnitName){
							displayCitation = displayCitation + ", " + Archives.components[1].orgUnitName;
						}
					}

					displayCitation = displayCitation + ", The New York Public Library. " + document.URL.replace("#overview","").replace("#detailed",""); 


					//remove any filter highliting
					if (c.title){
						c.title = c.title.replace('<span class="search-highlight">','').replace('</span>','')
					}else{
						c.title = ''
					}

					displayOrigination = displayOrigination.replace('<span class="search-highlight">','').replace('</span>','')

					if (c.dateStatement){
						c.dateStatement = c.dateStatement.replace('<span class="search-highlight">','').replace('</span>','')
					}else{
						c.dateStatement = '';
					}
					
					displayExtentStatement = displayExtentStatement.replace('<span class="search-highlight">','').replace('</span>','')
					path = path.replace('<span class="search-highlight">','').replace('</span>','')
					displayCitation = displayCitation.replace('<span class="search-highlight">','').replace('</span>','')

					metadata.a0 = c.title;					

					metadata.a20 = displayOrigination;

					metadata.a40 = c.dateStatement;

					metadata.a50 = displayExtentStatement;

					metadata.a55 = path;

					metadata.a60 = displayCitation;





					self.viewerOpen = true;

					

					self.colorBoxObj = $.colorbox(
							{
								fixed:true, 
								html:'<iframe sandbox="allow-same-origin allow-scripts allow-popups allow-forms" name="imageViewerIframe"></iframe>', 
								width: '95%', 
								height: '95%',
								scrolling: false,
						        onClosed:function(){
						            $("#cboxClose").removeClass("cboxCloseNew");
						            self.viewerOpen = false;

						        }
							});

					$("#cboxClose").text("x");
					$("#cboxClose").addClass("cboxCloseNew");

					//append a form to trigger the target 
					$("#imageViewerForm").remove();

					var form=$("<form/>").attr({
					    method: "post",
					    action: "http://digitalcollections.nypl.org/items/embedzoom",
					    target: "imageViewerIframe",
					    id: 'imageViewerForm'
					});

					form.append($("<input/>").attr({type: 'hidden', name:"items", value:JSON.stringify(embedDoc)}));
					form.append($("<input/>").attr({type: 'hidden', name:"metadata", value:JSON.stringify(metadata)}));




					$("body").append(form);

					form.submit();
					
					
					


					/*
					
				   $.colorbox({
				        open: true,
				        scrolling: false,
				        width:'90%',
				        height:'90%',
				        href:"http://dev.digitalcollections.nypl.org/items/embedzoom",
				        data:{items:embedDoc,metadata:metadata},
				        onClosed:function(){
				            //Do something on close.
				        }
				    });
						
					*/
					
					/*

					$.ajax({
					  type: "POST",
					  url: 'http://dev.digitalcollections.nypl.org/items/embedzoom',
					  data: {items:embedDoc,metadata:metadata},
					  success: function(data, textStatus, jqXHR){


					  	console.log(data);

					  },


					  dataType: 'html'
					});
					*/


				}else{



					//the get 

					var getString = '';


					_.each(c.image, function(image, index, list){

						//only do the first 10 images
						if (index>10){return}

						getString += 'items[][date]=' + encodeURIComponent(c.dateStatement) + "&";
						getString += 'items[][title]=' + encodeURIComponent(c.title) + "&";
						getString += 'items[][imageID]=' + image.image_id + "&";
						getString += 'items[][uuid]=' + image.uuid + "&";

				

					});

					getString = "http://dev.digitalcollections.nypl.org/items/embedzoom?" + getString;
					$.colorbox({href: getString, width: '90%', height: '90%', iframe: true});
					




				}



				//This is the current functionality
				//$.colorbox({href: 'http://images.nypl.org/index.php?id=' + c.image[0].imageId + '&t=w', photo: true});




			}




		},

		render: function() {

	 

		}




	});

}).call(this);