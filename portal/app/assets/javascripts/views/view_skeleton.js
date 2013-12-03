window.Archives.Views.skeleton = Backbone.View.extend({


	//a counter object to keep reference locked throughout the template calls
	counter : {count : -1},


	initialize: function() {


		this.render();


	},

	render: function() {



		var templateFunction = _.template(window.Archives.templates['skeleton']);
		var templateComponentFunction = _.template(Archives.templates['singleComponent'][Archives.collectionResponse.component_layout_id]);

		var html = templateFunction({model: this.model, templateFunction: templateFunction, templateComponentFunction: templateComponentFunction, counter:this.counter});

		this.$el.html(html);

		Archives.eventAgg.trigger("global:containerListChanged");
 

	}







});