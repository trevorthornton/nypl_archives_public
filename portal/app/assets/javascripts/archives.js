(function() {

  "use strict";


  window.Archives = {
    Models: {},
    Collections: {},
    Views: {},
    Routers: {},


    eventAgg: _.extend({}, Backbone.Events),


    collection_id: -1,

    components : {},            //an array of all of this collections components
    browser: {},
    viz: {},
    network: {},
    data: {},
    filter: {},
    templates: {},


    nav_check_subseries: false,  //check on subseries positions for sticky header, updates when in a series with subseries    


    debug: false,

    debug_verbose: false,    


    initialize: function() {
      


      //depending on the page we might not need to initlaize, if the below data is in the global namespace then we can continue to render
      if (typeof collection_structure === 'undefined'){
        return false;
      }

      if (typeof collection_structure.id === 'undefined'){
        return false;
      }



      //this is basic info passed from the backend about a collection 
      this.collectionStructure = collection_structure;
      this.collectionResponse = collection_response;
      this.componentCount = collection_component_count;

      this.collectionId = collection_structure.id;

      collection_component_count = null;
      collection_structure = null;

      //register the ask, controls passing info
      this.ask = new window.Archives.Models.Ask({});

      //register these vars because config use them
      this.ask.set('componentCount',function(){return window.Archives.componentCount;});
      this.ask.set('collectionId',function(){return window.Archives.collectionId;});


      this.config = new window.Archives.Models.Config({});

      


      if (this.debug)
        console.log('Hello from Archives!');




      //start the history 
      Backbone.history.start();

      
      //start the data module
      this.data.initalize();

      //format the series
      this.data.buildSeriesCollection();



      //render the navigation 
      this.navSide = new window.Archives.Views.navSide({model: this.collectionStructure, el: $("#nav-detailed-list ul")});

      this.navOverviewSide = new window.Archives.Views.navOverviewSide({model: {}, el: $("#navTab")});


      this.navSticky = new window.Archives.Views.navSticky({model: {series: "", subseries: ""}, el: $("#nav-title-holder")});

      this.navWindow = new window.Archives.Views.navWindow({model: {}, el: $(window)});

      this.navFilter = new window.Archives.Views.navFilter({model: {}, el: $("#nav-filter")});

      //look at navWindow for the events, this for the actions
      this.digitalAssets = new window.Archives.Views.digitalAssets({model: {}, el: $("#collection-content-detailed, #collection-content-searchresults")});

      //The nav buttons
      this.navSelectButtons = new window.Archives.Views.navSelectButtons({model: {}, el: $(".collection-view-select").first()});

      //the admin links
      this.adminLinks = new window.Archives.Views.adminLinks({model: {}, el: $(".admin-links")});


      //pie chart is the status progress indicator
      this.statusPieChart = new window.Archives.Views.statusPieChart({model: {}, el: $("#status-pie")});

      //the minimap
      this.navVizControl = new window.Archives.Views.navVizControl({model: {}, el: $("#viz-nav-control")});


      if (this.a('renderMode') == 'skeleton'){
        this.skeleton = new window.Archives.Views.skeleton({model: this.collectionStructure, el: $("#collection-content-detailed")});
      }




      this.network.downloadComponents();


      return;


      this.format_series();

      if (Archives.batch_output)
        if (collection_component_count === 0){document.title = 'done';}

    },


  };

  $(document).ready(function() {
    return Archives.initialize();
  });




}).call(this);