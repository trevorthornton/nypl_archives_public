(function () {

   "use strict";

	window.Archives.Views.navSelectButtons = Backbone.View.extend({



		events : {
			"click"		: "click"
		},


		initialize: function() {

		},


		click : function(e){


			//did we click the detailed button?
			if ($(e.target).attr('href')==='#detailed' && $(e.target).hasClass('disabled') === false){



				Archives.allRoutes.navigate("#detailed", {trigger: true, replace: true});

				e.preventDefault();
				return false;



			}else if($(e.target).attr('href')==='#overview' && $(e.target).hasClass('disabled') === false){

				Archives.allRoutes.navigate("#overview", {trigger: true, replace: true});
				e.preventDefault();
				return false;

			}



		},



	});

}).call(this);