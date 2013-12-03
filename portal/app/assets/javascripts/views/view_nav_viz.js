(function () {

   "use strict";

	window.Archives.Views.navViz = Backbone.View.extend({

		enabled: false,

		mouseButtonOn : false,

		mouseInHighlight: false,

		mouseAboveHighlight: false,

		highlight : null,

		offsetTop : 0,

		vizHeight : 0,

		noScroll: false,

		clickTimer: null,

		holdDownMulitplyer: 1,

		highlightPos: 0,
		highlightPosLocal: 0,

		fromTopOfHighlight: -1,


		events : {

			"mousemove" : "mousemove",
			"mousedown" : "mousedown",
			"mouseup"   : "mouseup",
			"click"		: "click",
			'mouseleave' : 'mouseleave'
		},


		initialize: function() {

			var self = this;

			$("#nav-viz .highlight").remove();

			Archives.eventAgg.on("global:resize",this.resizeGlobal, this);

			Archives.eventAgg.on("global:scrolling",this.scrolling, this);

			this.resize();

			this.placeHighlight($(window).scrollTop());


			Archives.eventAgg.on("global:seriesChange",this.seriesChange, this);

			Archives.eventAgg.on('navFilter:isFiltered', this.seriesChange, this);

			Archives.eventAgg.on('navFilter:isNotFiltered', this.seriesChange, this);



		},

		

		seriesChange: function(){

			var self = this;

			if (this.enabled){
				
				Archives.navViz.enabled = false;
				$('#iframe-minimap').remove();

				//Archives.viznav.init();
				this.renderTimer = window.setInterval(function(){
					if (Archives.a('domInsertComplete')){
						Archives.viznav.init();
						window.clearInterval(self.renderTimer);
					}
					
				},500);

			}

		},

		scrolling: function(){



			if (this.noScroll) return;

			this.placeHighlight();


		},

		placeHighlight : function(useScrollTop){

			this.resize();


			this.highlightPos = $(window).scrollTop() * Archives.viznav.reduce;


			//are we using a passed postion
			if (useScrollTop)
				this.highlightPos = useScrollTop * Archives.viznav.reduce;


			var backPos = 0;

			var times = 1.5;

			//if (this.highlightHeight < 20)
			//	times = 10;
			//if (this.highlightHeight < 50)
			//	times = 5;
			

			var displayPercent = (Archives.viznav.displayHeight - (this.highlightHeight*times) ) / Archives.viznav.canvasHeight;



			backPos = this.highlightPos * (1 - displayPercent);


			if (isNaN(backPos) || backPos <= 0 || backPos === Infinity ){
				Archives.viznav.display(0);
			}else{
				Archives.viznav.display(backPos);
			}

			this.highlightPosLocal = Archives.viznav.drawHighlight(this.highlightPos,this.highlightHeight);



		},


		resizeGlobal: function(){

			//resize the iframe
			Archives.viznav.iframe.css("height",  $(window).height() - Archives.viznav.topOffset);

			//resize the canvas
			Archives.viznav.displayContext.canvas.height = $(window).height() - Archives.viznav.topOffset;
			Archives.viznav.displayHeight = Archives.viznav.displayContext.canvas.height - 2;


			//redraw
			this.placeHighlight($(window).scrollTop());


		},


		resize: function(){

			

			var height = $(window).height() * Archives.viznav.reduce;

			height -= $(".navbar").first().outerHeight(true) * Archives.viznav.reduce;
			
			height -= $("#nav-title-holder").height() * Archives.viznav.reduce;

			this.highlightHeight = height;





		},

		click : function(e){

			if(this.mouseAboveHighlight){

				if ($(window).scrollTop() <= 0){
					this.placeHighlight(0);
					return;
				}
					

				this.placeHighlight($(window).scrollTop() - (25 * this.holdDownMulitplyer));
				$("html, body").scrollTop($(window).scrollTop() - (25 * this.holdDownMulitplyer));

			}else{

				if ($(window).height()+ $(window).scrollTop() >= $(document).height()){

					this.placeHighlight($(window).scrollTop());
					return;
				}
					

				this.placeHighlight($(window).scrollTop() + (25 * this.holdDownMulitplyer));
				$("html, body").scrollTop($(window).scrollTop() + (25 * this.holdDownMulitplyer));

			}


		},


		mouseleave: function(e){

			$(this.el).mouseup();

		},

		mousemove: function(e){

			var self = this;

			//_.debounce(function(){



			if (e.clientY >= this.highlightPosLocal && e.clientY  <= this.highlightPosLocal + this.highlightHeight){
				$(self.el).removeClass("down").removeClass("up");
				$(this.el).addClass("openhand");
				this.mouseInHighlight = true;
				
			}else{
				$(this.el).removeClass("openhand");
				this.mouseInHighlight = false;

				if (e.clientY - Archives.viznav.topOffset < this.highlightPosLocal){
					this.mouseAboveHighlight = true;
					$(self.el).removeClass("down").addClass("up");
				}else{
					this.mouseAboveHighlight = false;
					$(self.el).removeClass("up").addClass("down");
				}


			}


			if (this.mouseButtonOn){

				var cursorPos = e.clientY - this.fromTopOfHighlight;

				var pos  = cursorPos / Archives.viznav.displayHeight;


				pos = Archives.viznav.canvasHeight * pos;

				pos = pos * 6;


				this.noScroll = true;

				if (pos < 0 ){
					pos = 0;
				}


				if (pos > $(document).height()){
					this.placeHighlight($(window).scrollTop());
					return;
				}


			}


			if (this.mouseButtonOn && this.mouseInHighlight){		
				this.placeHighlight(pos);
				$("html, body").scrollTop(pos);
			}else{

				if( this.mouseButtonOn && this.noScroll && self.clickTimer === null){
					this.placeHighlight(pos);
					$("html, body").scrollTop(pos);

				}else{

					this.noScroll = false;

				}

				
			}

		},




		mouseup: function(e){
			

			this.mouseButtonOn=false;

			this.noScroll = false;

			window.clearInterval(this.clickTimer);
			self.clickTimer  = null;

			$(this.el).removeClass("closehand");
			if (!this.mouseInHighlight){
				$(self.el).addClass("openhand");
			}

			this.holdDownMulitplyer = 1;

		},


		mousedown: function(e){

			var self = this;


			this.mouseButtonOn=true;

			this.noScroll = true;


			if (!this.mouseInHighlight){

				self.clickTimer = window.setInterval(function(){

					if (self.mouseInHighlight){
						window.clearInterval(self.clickTimer);
						self.clickTimer = null;
						return false;
					}


					self.holdDownMulitplyer++;

					self.click();

				},50);

			}else{

				$(this.el).removeClass("openhand");
				$(self.el).addClass("closehand");

				this.fromTopOfHighlight = e.clientY - this.highlightPosLocal;

			}

		},

		destroyPlaceholder: function(){
			$("#viz-nav-loading-placeholder").remove();
		},




	});

}());