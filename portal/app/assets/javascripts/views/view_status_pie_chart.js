
/*	NYPL Archives Platform
//	
//	view_status_pie_chart.js
//
//	Controls the status indicator, builds a canvas one if canvas is avilable
//	
//
*/


(function() {

	"use strict";


	window.Archives.Views.statusPieChart = Backbone.View.extend({



		canvasSupported : !!window.HTMLCanvasElement,

		canvas : null,

		lastPercent : 0,


		initialize: function() {


			Archives.eventAgg.on('network:downloadedComponentPageErrorFatal',this.fatalNetworkError, this);

			Archives.eventAgg.on('data:pageProcessed', this.updatePercent, this);

			Archives.eventAgg.on('data:pageLoaded', this.pageLoaded, this);


			if (this.canvasSupported){


				$(this.el).css("background", "none");




				$(this.el)
					.append(
						$("<CANVAS>")
							.attr("height", "95")
							.attr("width", "95")						
							.attr("id", "pie-chart-canvas")
					);


				this.canvas = document.getElementById("pie-chart-canvas");



			}


		},


		pageLoaded: function(){

			this.drawPieSegment(parseInt(100));

			$(this.el).css("background-position", 10 * -72.20 + "px 0px").fadeOut("slow");

			if (Archives.batchOutput){
				setTimeout(function(){

					window.Archives.viznav.init();

				}, 1000);
			}
			
		},

		updatePercent: function(percent){

			var self = this;

			$(this.el).css("display","block");
			

			if (this.canvasSupported){



				self.drawPieSegment(parseInt(percent));
				this.lastPercent = percent;


			}else{


				
				$(this.el).css("background-position", ((Math.ceil(percent / 10) * 10) / 10) * -72.20 + "px 0px");

			}



		},



		fatalNetworkError : function(){


			var stausArea = $(this.el);

			stausArea.empty();

			stausArea.show();

			var error = $("<DIV>");

			error
				.css("height","100px")
				.css("width","100px")
				.css("font-family",'"Icomoon"')
				.css("color","#e74c3c")
				.css("font-size","90px")
				.css("position","absolute")
				.css("top","22px");

			var errorMsg = $("<DIV>");

			errorMsg
				.css("width","179px")
				.css("color","#e74c3c")
				.css("border","1px solid grey")
				.css("text-align","center")
				.css("position","absolute")
				.css("padding","5px")
				.css("left","-198px")
				.css("background-color","white")
				.css("border-radius","5px")
				.css("top","-3px")
				.html("Error Loading Component Data.<br>Please Refresh The Page.");


			error.text("x");
			stausArea.append(error).append(errorMsg);




		},


		drawPieSegment : function(percent) {

			var orgPercent = percent;

			percent = 360 * (percent/100);

			var  degreesToRadians  = function(degrees) {
			    return (degrees * Math.PI)/180;
			}

			var sumTo = function(a, i) {
			    var sum = 0;
			    for (var j = 0; j < i; j++) {
			      sum += a[j];
			    }
			    return sum;
			}


			var context = this.canvas.getContext("2d");


		    var centerX = Math.floor(this.canvas.width / 2);
		    var centerY = Math.floor(this.canvas.height / 2);

		    var radius = Math.floor(this.canvas.width / 2);



			context.beginPath();
			context.arc(centerX, centerY, radius, 0, 2 * Math.PI, false);
			context.lineWidth = 0.5;
			context.strokeStyle = 'darkgrey';
			context.stroke();


		

			if (orgPercent !== 100){

				var from = 360 * (this.lastPercent/100);

				var clear = window.setInterval(function(){



					if (from < percent){




						var startingAngle = degreesToRadians(-90);
						var arcSize = degreesToRadians(from);
						var endingAngle = startingAngle + arcSize;


						context.beginPath();
						context.moveTo(centerX, centerY);
						context.arc(centerX, centerY, radius, startingAngle, endingAngle, false);
						context.closePath();

						context.fillStyle = "#989546";

						context.fill();

						from++;




					}else{

						window.clearInterval(clear);
					}


				}, 25);
			
			}else{


				var startingAngle = degreesToRadians(-90);
				var arcSize = degreesToRadians(360);
				var endingAngle = startingAngle + arcSize;


				context.beginPath();
				context.moveTo(centerX, centerY);
				context.arc(centerX, centerY, radius, startingAngle, endingAngle, false);
				context.closePath();

				context.fillStyle = "#989546";

				context.fill();




			}
			



		}







	})

}).call(this);