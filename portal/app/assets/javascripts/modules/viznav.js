
(function() {

  "use strict";

	window.Archives.viznav = {

		
		navVizDom: null,

		canvas: null,

		reduce: 0.2,

		canvasPages : null,

		canvasHeight : 0,

		canvasCache : [],

		displayContext: null,

		displayHeight: 0,

		displayWidth: 150,

		displayHeightPosition: 0,

		topOffset: 0,


		init : function(){


			if (Archives.navViz)
				if (Archives.navViz.enabled)
					return false;

			//$("body, .collections-show").css("padding","0");
			//$("body, .collections-show").css("margin","0");
			//$(".navbar").css("display","none");




			//there is a 6000px limit to canvas size....of course... so make multiple ones	
			//http://stackoverflow.com/questions/6081483/maximum-size-of-a-canvas-element

			this.canvasHeight = 0;
			var pageHeight = 0;
			var pageCounter = 0;

			var self = this;

			var totalHeight = 0;




			$("body").append(

				$("<iframe>")
				.attr("name","iframe-minimap")
				.attr("id", "iframe-minimap")


			);

			this.canvasCache = [];

			if (Archives.filter.isFiltered){
				var all = $("#collection-content-searchresults .collection-detailed-row")
			}else{
				var all = $("#collection-content-detailed .collection-detailed-row")
			}

			//for (x=0; x < all.length; x++){
			for (var x=0; x < all.length; x++){

				//var height = $(e).outerHeight(true) * self.reduce;

				var e = all[x];
				
				var height = this.returnRealHeight($(e),all,x) * self.reduce;

				self.canvasHeight += height;
				totalHeight += height;
				pageHeight += height;

				if (pageHeight >= 6000){

					//make a new canvas
					var canvas = document.createElement("canvas");
					canvas.width = self.displayWidth;
					canvas.height = pageHeight;

					var context = canvas.getContext("2d");

					self.canvasCache.push(

						{
							id: pageCounter,
							context : context,
							height: canvas.height
						}


					);

					pageCounter++;
					pageHeight = 0;



				}



			}



			//add one for the last bit remaning if there
			if (pageHeight < 6000){

					pageCounter++;
					var canvas = document.createElement("canvas");
					canvas.width = self.displayWidth;
					canvas.height = pageHeight;

					var context = canvas.getContext("2d");	

					self.canvasCache.push(
						{
							id: pageCounter,
							context : context,
							height: canvas.height
						}


					);

			}

			//if it all fits on one page how nice.
			if (self.canvasHeight < 6000){

					var canvas = document.createElement("canvas");
					canvas.width = this.displayWidth;
					canvas.height = pageHeight;

					var context = canvas.getContext("2d");	
					self.canvasCache = [];
					self.canvasCache.push(
						{
							id: 0,
							context : context,
							height: pageHeight
						}
					);
			}





			if (Archives.batchOutput)
				this.displayWidth = "250";

			

			//var html = _.template(Archives.templates['navViz'])( {domHeight: $(window).height(), canvasPages: canvasPages, canvasWidth: this.displayWidth  } );

			//$("body").append(html);

			//this.navVizDom = $("#nav-viz");




			//firefox ie bug, the iframe will not be accessed until it loads, so wait a sec

			setTimeout ( function () {


				self.topOffset = $(".nav-top").first().outerHeight(true) + $("#nypl-header").first().outerHeight(true) + 2;

				self.iframe = $("#iframe-minimap");
				self.iframeBody = self.iframe.contents().find("body");

				self.iframeBody.css("margin",0).css("padding",0);

				self.iframe.addClass("viz-nav-holder");

				self.iframe.css("top",  self.topOffset);
				self.iframe.css("width", self.displayWidth);
				self.iframe.css("height",  $(window).height() - self.topOffset);

				self.iframeBody.empty();

				self.iframeBody.append("<style>.openhand{ cursor: url(data:image/png;base64,AAACAAEAICACAAcABQAwAQAAFgAAACgAAAAgAAAAQAAAAAEAAQAAAAAAAAEAAAAAAAAAAAAAAgAAAAAAAAAAAAAA////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD8AAAA/AAAAfwAAAP+AAAH/gAAB/8AAA//AAAd/wAAGf+AAAH9gAADbYAAA2yAAAZsAAAGbAAAAGAAAAAAAAA//////////////////////////////////////////////////////////////////////////////////////gH///4B///8Af//+AD///AA///wAH//4AB//8AAf//AAD//5AA///gAP//4AD//8AF///AB///5A////5///8=), auto;} .closehand{ cursor: url(data:image/png;base64,AAACAAEAICACAAcABQAwAQAAFgAAACgAAAAgAAAAQAAAAAEAAQAAAAAAAAEAAAAAAAAAAAAAAgAAAAAAAAAAAAAA////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD8AAAA/AAAAfwAAAP+AAAH/gAAB/8AAAH/AAAB/wAAA/0AAANsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//////////////////////////////////////////////////////////////////////////////////////gH///4B///8Af//+AD///AA///wAH//+AB///wAf//4AH//+AD///yT/////////////////////////////8=), auto;} .up{ cursor: n-resize;} .down{cursor:s-resize;}</style>");


				//debug settings
				//self.iframe.css("top","0px");
				//self.iframe.css("height",$(window).height());
				//self.iframe.css("width",self.displayWidth);


				self.iframeBody.append(

					$("<canvas>")
						.attr("width",self.displayWidth)
						.attr("height",self.iframe.height())
						.attr("id","nav-viz-display")
				);



				//this.displayContext = $("#nav-viz-display")[0].getContext("2d");
				self.displayContext = self.iframeBody.find('#nav-viz-display')[0].getContext("2d");
				self.displayHeight = self.iframe.height()






				self.render();

				if (Archives.batchOutput)
					self.save();

				if (Archives.batchOutput)
					document.title = 'done';

				Archives.navViz = new window.Archives.Views.navViz({model: {}, el: self.iframeBody.find('#nav-viz-display')});
				Archives.navViz.enabled = true;

				Archives.navViz.destroyPlaceholder();



			}, 300);

		},


		drawLine: function(pos){


			this.display(0);

			var context = this.canvasCache[0].context;

			context.fillStyle = 'black';
		    context.strokeStyle = 'black';


		    context.beginPath();
		    context.moveTo(0, pos); 
		    context.lineTo(450, pos);
		    context.lineWidth = 1;
		    context.stroke();
		    context.closePath();  


		},


		drawHighlight: function(y,h){




			this.displayContext.fillStyle = "rgba(0, 0, 0, 0.25)";

			var localY = y - this.displayHeightPosition;

			this.displayContext.fillRect(0, localY, this.displayWidth, h);

			return localY;
		},


		display: function(pos){



			//the pos being passed is a global positon in the document

			this.displayHeightPosition = pos;

			//so first find the page that this position starts on
			var realativeHeight = 0;
			var usePage = 0;


			for (var x=0; x < this.canvasCache.length; x++){

				realativeHeight += this.canvasCache[x].height;

				if (pos < realativeHeight){
					usePage = x;
					break;
				}

			}

			//console.log("This pos starts on page:", usePage,realativeHeight);


			//we know what page, now we need to know where on the canvas cache do we start copying from
			//so take the total height of where we are, take out the current page height, and minus that from the pos requests = the local Y position on this page
			var localStart = pos - (realativeHeight - this.canvasCache[usePage].height)

			//console.log("This pos starts locally on the page:", localStart);


			//now the problem is, does the current canvas have enough content to fill up the display area?
			var pixlesLeftOnThisPage = this.canvasCache[usePage].height - localStart;


			//console.log("There are X pixles left on this page:", pixlesLeftOnThisPage);

			
			this.displayContext.clearRect(0,0,this.displayWidth,this.displayHeight);


			if (pixlesLeftOnThisPage >= this.displayHeight){


				//console.log(this.canvasCache[usePage].context.canvas, localStart, this.displayWidth, this.displayHeight);
				//yes it will all fit
				this.displayContext.drawImage(this.canvasCache[usePage].context.canvas, 0, localStart, this.displayWidth, this.displayHeight, 0, 0, this.displayWidth, this.displayHeight);


			}else if (this.canvasHeight <= this.displayHeight){


				this.displayContext.drawImage(this.canvasCache[usePage].context.canvas, 0, 0);

			}else if(pixlesLeftOnThisPage <= this.displayHeight && this.canvasCache.length === 1){ 

				//console.log(0, localStart, this.displayWidth, pixlesLeftOnThisPage, 0, 0, this.displayWidth, pixlesLeftOnThisPage);

				this.displayContext.drawImage(this.canvasCache[usePage].context.canvas, 0, localStart, this.displayWidth, pixlesLeftOnThisPage-1, 0, 0, this.displayWidth,pixlesLeftOnThisPage-1);



			}else{


				//need to copy a bit from the next page too


				var leftovers = this.displayHeight - pixlesLeftOnThisPage;

				//write the rest of this page
				this.displayContext.drawImage(this.canvasCache[usePage].context.canvas, 0, localStart, this.displayWidth, pixlesLeftOnThisPage, 0, 0, this.displayWidth, pixlesLeftOnThisPage);
			
				if (this.canvasCache[usePage+1])
					this.displayContext.drawImage(this.canvasCache[usePage+1].context.canvas, 0, 0, this.displayWidth, leftovers, 0, pixlesLeftOnThisPage, this.displayWidth, leftovers);





			}




		},


		returnRealHeight: function(e,all,x){

			var height = e.height();

			var thisTopMargin = parseInt(e.css("margin-top").replace("px"));
			var thisBottomMargin = parseInt(e.css("margin-bottom").replace("px"));

			var previousBottomMargin = 0;
			var nextTopMargin = 0;

			//see if we can get the previous margins
			if (all[x-1]){
				previousBottomMargin = parseInt($(all[x-1]).css("margin-bottom").replace("px")) || 0;
			}
			if (all[x+1]){
				nextTopMargin = parseInt($(all[x+1]).css("margin-top").replace("px")) || 0;
			}

			//if the previous node had a larger bottom margin then this ones top margin it would have used that one in the previous mesurment
			if (previousBottomMargin < thisTopMargin){
				height = height + thisTopMargin;
			}

			//if the next top margin is smaller than this ones use this one because it will be the one to render
			if (nextTopMargin < thisBottomMargin){
				height = height + thisBottomMargin;
			}
			
			//if they both match only use one
			if (previousBottomMargin === thisTopMargin && nextTopMargin === thisBottomMargin){
				height = height + thisBottomMargin;
			}

			//the 
			if (previousBottomMargin > thisTopMargin && nextTopMargin === thisBottomMargin){
				height = height + thisBottomMargin;
			}

			return height;



		},


		render: function(){


			if ($(".series").first().length !== 0){
				var fontSizeSeries = parseInt($(".series").first().css("font-size").replace("px",'')) || 21;
			}else{
				var fontSizeSeries = 21;

			}

			if ($(".subseries").first().length !== 0){
				var fontSizeSubseries = parseInt($(".subseries").first().css("font-size").replace("px",'')) || 18;
			}else{
				var fontSizeSubseries = 18;

			}

			if ($(".file").first().length > 0){
				var fontSizeFile = parseInt($(".file").first().css("font-size").replace("px",'')) || 16;
			}
			if ($(".item").first().length > 0){
				var fontSizeFile = parseInt($(".item").first().css("font-size").replace("px",'')) || 16;
			}		

			var fontSizeDesc = parseInt($(".container-desc").first().css("font-size").replace("px",'')) || 14;

			if ($(".remainder-width-1").first().length > 0){
				var remainderWidth1 = $(".remainder-width-1").first().position().left - 320 || 150;
			}

			if ($(".remainder-width-2").first().length > 0){
				var remainderWidth2 = $(".remainder-width-2").first().position().left - 330 || 150;
			}

			if ($(".remainder-width-3").first().length > 0){
				var remainderWidth3 = $(".remainder-width-3").first().position().left - 330 || 250;
			}
			if ($(".remainder-width-4").first().length > 0){
				var remainderWidth4 = $(".remainder-width-4").first().position().left - 330 || 350;
			}
			if ($(".remainder-width-5").first().length > 0){
				var remainderWidth5 = $(".remainder-width-5").first().position().left - 330 || 450;
			}

			if ($(".remainder-width-6").first().length > 0){
				var remainderWidth6 = $(".remainder-width-6").first().position().left - 330 || 550;
			}

			//this.canvas = $("#nav-viz-0")[0];

			//this.context = this.canvas.getContext("2d");

			this.context = this.canvasCache[0].context;


			if (Archives.filter.isFiltered){
				var all = $("#collection-content-searchresults .collection-detailed-row")
			}else{
				var all = $("#collection-content-detailed .collection-detailed-row")
			}

			var currentY = 0;
			var localY = 0;
			var currentContext = 0;

			/*
			//we have to look ahead and resize the canvas for the real size of the elements
			for (var x=0; x < all.length; x++){

				var e = $(all[x]);
				var height = e.outerHeight(true) * this.reduce;

				localY = localY + height;

				if (localY + height > 8000){				

					this.context.canvas.height = localY + height;	

					currentContext = currentContext + 1;
					this.context = this.canvasCache[currentContext];
					localY = 0;
				}			

			}
			*/



			var currentY = 0;
			var localY = 0;
			var currentContext = 0;

			//for (x=0; x < all.length; x++){
			for (var x=0; x < all.length; x++){
				



				if (localY >= this.canvasCache[currentContext].height){		

					//$("body").append(this.canvasCache[currentContext].context.canvas);	
					//$("body").append($("<hr>"));
					//$("body").append($("<span>").text("~break~"));

					localY = 0;

					currentContext = currentContext + 1;


					//this.canvas = $("#nav-viz-"+currentContext)[0];	
					//this.context = this.canvas.getContext("2d");
					this.context = this.canvasCache[currentContext].context;

				}



				var e = $(all[x]);
				var width = e.width();
				

				//a little covluted here due to collapsed margins
				var height = this.returnRealHeight(e,all,x);

				height = height * this.reduce;
				width = width * this.reduce;




	/*
				if (previousBottomMargin >= thisTopMargin){
					height = height - thisTopMargin;
				}


	*/

				
				//this.context.moveTo(0, currentY);

				//this.context.lineTo(0, width);
				//this.context.fillStyle = '#'+Math.floor(Math.random()*16777215).toString(16);

				if (Archives.batchOutput){
					this.context.fillStyle = "rgba(255, 255, 255, 0)";
				}else{
					this.context.fillStyle = "rgba(245, 245, 245, 1)";

				}


				//this.context.fillStyle = "rgba(" + Math.floor(Math.random() * (255 - 1 + 1) + 1) + ", " + Math.floor(Math.random() * (255 - 1 + 1) + 1)  + ", " + Math.floor(Math.random() * (255 - 1 + 1) + 1)  + ", 0.25)";	
				//e.css("background-color",this.context.fillStyle);

				
				this.context.fillRect(0, localY, width, height);



				var children = e.children();



				//this is the container list div
				if (children[0]){

					if (children[0].className.search("series") === -1 && children[0].className.search("subseries") === -1){


						//not a series

						this.context.textBaseline = "top";
						this.context.fillStyle = 'grey';
						this.context.font =  fontSizeDesc*this.reduce + "px sans-serif";
						var useText = children[0].children[0].textContent || children[0].children[0].innerText;
						this.context.fillText(useText, 0, localY);



					}




				}
				if (children[1]){

					var xPos = 0;

					if (children[1].className.search('remainder-width-2') !== -1){
						xPos = remainderWidth2;
					}else if (children[1].className.search('remainder-width-3') !== -1){
						xPos = remainderWidth3;
					}else if (children[1].className.search('remainder-width-4') !== -1){
						xPos = remainderWidth4;
					}else if (children[1].className.search('remainder-width-5') !== -1){
						xPos = remainderWidth5;
					}else if (children[1].className.search('remainder-width-6') !== -1){
						xPos = remainderWidth6;
					}else if (children[1].className.search('remainder-width-1') !== -1){
						xPos = remainderWidth1;
					}


					xPos = xPos * this.reduce;

					var textMetrics = 0;
					var textWidth = 0;
					var textHeight = 0;



					for (var y =0; y < children[1].children.length; y++){

						var useText = '';

						//console.log(children[1].children[y]);

						//console.log(children[1].children[y].offsetParent);

						if (children[1].children[y].className.search("series") !== -1 && children[1].children[y].className.search("subseries") === -1){

							this.context.textBaseline = "top";
							this.context.fillStyle = '#0c5aa6';

							useText = children[1].children[y].textContent || children[1].children[y].innerText;

							this.context.font =  fontSizeSeries*this.reduce + "px sans-serif";
							this.context.fillText(useText, xPos, localY);
							textMetrics = this.context.measureText(children[1].children[y].innerText);
							textWidth = textMetrics.width;	
							textHeight = fontSizeSeries*this.reduce + this.reduce;



						}else if (children[1].children[y].className.search("subseries") !== -1){

							this.context.textBaseline = "top";
							this.context.fillStyle = '#5E0DAC';
							this.context.font =  fontSizeSubseries*this.reduce + "px sans-serif";

							useText = children[1].children[y].textContent || children[1].children[y].innerText;

							this.context.fillText(useText, xPos, localY);
							textMetrics = this.context.measureText(children[1].children[y].innerText);
							textWidth = textMetrics.width;	
							textHeight = fontSizeSubseries*this.reduce + this.reduce;


						}else if (children[1].children[y].className.search("title") !== -1 ){

							this.context.textBaseline = "top";
							this.context.fillStyle = 'grey';

							this.context.font =  fontSizeFile*this.reduce + "px sans-serif";

							useText = children[1].children[y].textContent || children[1].children[y].innerText;

							this.context.fillText(useText, xPos, localY);
							textMetrics = this.context.measureText(children[1].children[y].innerText);
							textWidth = textMetrics.width;	
							textHeight = fontSizeFile*this.reduce + this.reduce;



						}


						if (children[1].children[y].className.search("date") !== -1 ){

							this.context.textBaseline = "top";
							this.context.fillStyle = 'grey';

							this.context.font =  fontSizeDesc*this.reduce + "px sans-serif";
							useText = children[1].children[y].textContent || children[1].children[y].innerText;


							this.context.fillText(useText, xPos + textWidth, localY);
							
							textMetrics = this.context.measureText(children[1].children[y].innerText);
							textWidth = textWidth + textMetrics.width;	


						}
						if (children[1].children[y].className.search("extent") !== -1 ){

							this.context.textBaseline = "top";
							this.context.fillStyle = 'grey';

							this.context.font =  fontSizeDesc*this.reduce + "px sans-serif";
							useText = children[1].children[y].textContent || children[1].children[y].innerText;


							this.context.fillText(useText, xPos + textWidth, localY);
							
							textMetrics = this.context.measureText(children[1].children[y].innerText);
							textWidth = textWidth + textMetrics.width;	


						}




						if (children[1].children[y].className.search("bioghist") !== -1){

							var eWidth = children[1].children[y].offsetWidth * this.reduce;
							var eHeight = children[1].children[y].offsetHeight * this.reduce;

							useText = children[1].children[y].textContent || children[1].children[y].innerText;

							var lines = this.formatTextToBlock(useText,fontSizeDesc,eHeight,eWidth);

							this.context.textBaseline = "top";
							this.context.fillStyle = 'grey';

							this.context.font =  fontSizeDesc*this.reduce + "px sans-serif";

							for(var n = 0; n < lines.length; n++) {
								this.context.fillText(lines[n], xPos, localY + textHeight);							
								textHeight = textHeight + fontSizeDesc*this.reduce;	
							}

						}


						if (children[1].children[y].className.search("scopecontent") !== -1){

							var eWidth = (children[1].children[y].offsetWidth- xPos) * this.reduce;
							var eHeight = children[1].children[y].offsetHeight * this.reduce;

							useText = children[1].children[y].textContent || children[1].children[y].innerText;

							var lines = this.formatTextToBlock(useText,fontSizeDesc,eHeight,eWidth);

							this.context.textBaseline = "top";
							this.context.fillStyle = 'grey';

							this.context.font =  fontSizeDesc*this.reduce + "px sans-serif";

							for(var n = 0; n < lines.length; n++) {
								this.context.fillText(lines[n], xPos, localY + textHeight);							
								textHeight = textHeight + fontSizeDesc*this.reduce;	
							}

						}

						if (children[1].children[y].className.search("note") !== -1){

							var eWidth = children[1].children[y].offsetWidth * this.reduce;
							var eHeight = children[1].children[y].offsetHeight * this.reduce;

							useText = children[1].children[y].textContent || children[1].children[y].innerText;

							var lines = this.formatTextToBlock(useText,fontSizeDesc,eHeight,eWidth);

							this.context.textBaseline = "top";
							this.context.fillStyle = 'grey';

							this.context.font =  fontSizeDesc*this.reduce + "px sans-serif";

							for(var n = 0; n < lines.length; n++) {
								this.context.fillText(lines[n], xPos, localY + textHeight);							
								textHeight = textHeight + fontSizeDesc*this.reduce;	
							}

						}	

						if (children[1].children[y].className.search("arrangement") !== -1){

							var eWidth = children[1].children[y].offsetWidth * this.reduce;
							var eHeight = children[1].children[y].offsetHeight * this.reduce;

							useText = children[1].children[y].textContent || children[1].children[y].innerText;

							var lines = this.formatTextToBlock(useText,fontSizeDesc,eHeight,eWidth);

							this.context.textBaseline = "top";
							this.context.fillStyle = 'grey';

							this.context.font =  fontSizeDesc*this.reduce + "px sans-serif";

							for(var n = 0; n < lines.length; n++) {
								this.context.fillText(lines[n], xPos, localY + textHeight);							
								textHeight = textHeight + fontSizeDesc*this.reduce;	
							}

						}	
						if (children[1].children[y].className.search("abstract") !== -1){

							var eWidth = children[1].children[y].offsetWidth * this.reduce;
							var eHeight = children[1].children[y].offsetHeight * this.reduce;

							useText = children[1].children[y].textContent || children[1].children[y].innerText;

							var lines = this.formatTextToBlock(useText,fontSizeDesc,eHeight,eWidth);

							this.context.textBaseline = "top";
							this.context.fillStyle = 'grey';

							this.context.font =  fontSizeDesc*this.reduce + "px sans-serif";

							for(var n = 0; n < lines.length; n++) {
								this.context.fillText(lines[n], xPos, localY + textHeight);							
								textHeight = textHeight + fontSizeDesc*this.reduce;	
							}

						}	

						if (children[1].children[y].className.search("accessrestrict") !== -1){

							var eWidth = children[1].children[y].offsetWidth * this.reduce;
							var eHeight = children[1].children[y].offsetHeight * this.reduce;

							useText = children[1].children[y].textContent || children[1].children[y].innerText;

							var lines = this.formatTextToBlock(useText,fontSizeDesc,eHeight,eWidth);

							this.context.textBaseline = "top";
							this.context.fillStyle = 'grey';

							this.context.font =  fontSizeDesc*this.reduce + "px sans-serif";

							for(var n = 0; n < lines.length; n++) {
								this.context.fillText(lines[n], xPos, localY + textHeight);							
								textHeight = textHeight + fontSizeDesc*this.reduce;	
							}

						}	







					}





				}





				//console.log(e.children());

				currentY = currentY + height;
				localY = localY + height;

			}

		},


		formatTextToBlock: function(text, fontsize, height, width){

			//if (!text){var text = "";}


			width = width / 1.25;
			//we know ther is a specifc number of lines width of lines we can have so loop through each word, see if it would push it over the width,
	        var words = text.split(' ');
	        var line = '';

	        var lineArray = [];

			this.context.font =  fontsize*this.reduce + "px sans-serif";

	        for(var n = 0; n < words.length; n++) {

	          var testLine = line + words[n] + ' ';
	          var metrics = this.context.measureText(testLine);
	          var testWidth = metrics.width;	


	          if (testWidth > width && n > 0) {


	          	lineArray.push(line);

	          	line = words[n];

	          }else{

	          	line = testLine;

	          }


	        }

	        lineArray.push(line);

	        return lineArray;


		},


		save: function(){


			var avg = 0;
			var count = 0;
			var avgYear = 0;

			_.each(Archives.components,function(e,i){

				if (e.dateInclusiveStart){

					var year = parseInt(e.dateInclusiveStart);

					if (!isNaN(year)){

						avg = avg + year;
						count++;


						avgYear = Math.floor(avg/count);

					}

					

				}
				


			});



			$("#nav-viz canvas").each(function(i,e){



				

				var base64 = e.toDataURL();
				$.post("http://localhost:5000/", { name: Archives.collectionId + '-' + i + '-' + avgYear, data: base64 });




			});



		}







	}


}).call(this);
