/*  NYPL Archives Platform
//  
//  routes.js
//
//  
//  The routes used by the app and some navigations
//
*/

(function() {



    "use strict";


    window.Archives.Routers.Routes = Backbone.Router.extend({



        routes: {
            "detailed": "showDetailed",
            "overview": "showOverview",
            "c:component"      : "navigateToComponent"
        }




    });



    // Initiate the router
    window.Archives.allRoutes = new window.Archives.Routers.Routes();


    function showDetailed(){


        Archives.ask.set('onDetailPage',true);


        //a hook to disable the other javascript scroll check TODO: unifiy scroll check
        window.Archives.disableOverviewScroll = true;



        $("#collection-overview").fadeOut('fast',function(){
            $("#collection-detailed").fadeIn('fast');

            $("[href=#overview]").removeClass("disabled");
            $("[href=#detailed]").addClass("disabled");

            //$(".collection-head").css("padding-bottom","0px");
            //$("body").css("padding-top","234px");
            $("#fixed-nav-title").css("display","block");
            $("#fixed-nav-subtitle").css("display","block");
            Archives.eventAgg.trigger('global:containerListChanged');


        });


        $(window).scrollTop(0);
        $(window).trigger('scroll');

        Archives.eventAgg.trigger("global:routeDetailed");




    }


    window.Archives.allRoutes.on('route:showDetailed', function(actions) {

        showDetailed();

    });


    window.Archives.allRoutes.on('route:showOverview', function(actions) {


        $('#nav-title-holder').css("visibility","hidden");



        Archives.ask.set('onDetailPage',false);

        $("#collection-detailed").fadeOut('fast',function(){
            $("#collection-overview").fadeIn('fast');

            $("[href=#detailed]").removeClass("disabled");
            $("[href=#overview]").addClass("disabled");

            $("#fixed-nav-title").css("display","none");
            $("#fixed-nav-subtitle").css("display","none");
            
        });

        $(window).scrollTop(0);
        $(window).trigger('scroll');
        Archives.eventAgg.trigger("global:routeOverview");



    });




    Archives.allRoutes.on('route:navigateToComponent', function(actions) {

        if (isNaN(parseInt(actions))) return false;


        if (!Archives.a('onDetailPage')){
            showDetailed();
        }

        if (Archives.a('renderMode') === 'series' && typeof window.Archives.components[actions] === 'undefined'){

            //Archives.ask.set('activeSeries',parseInt(actions));


        }

        Archives.allRoutes.navTimeout =  window.setInterval(function(){
            Archives.eventAgg.trigger("navSticky:inTransition");
            tryToNavigate(actions);
        }, 100);





    });


    function tryToNavigate(id){



        if (Archives.a('renderMode')==='skeleton'){

            //is the data loaded?
            if (Archives.components[id]){

                //is the dom created??
                if ($("#c"+id).length > 0){
                    //is it populated?
                    if ($("#c"+id).text() !== 'Loading...'){


                        if (Archives.components[id].level_text === 'series' || Archives.components[id].level_text === 'subseries' ){

                            //since these are pre-rendered in the skeleton mode wait until the page is done loading before 
                            //scrolling because they will be jumping around as the dom inserts the components
                            if (!Archives.a('domInsertComplete')){
                                return false;
                            }


                        }




                            highlightComponent(id);
                            window.clearInterval(Archives.allRoutes.navTimeout);
                            return true;

                    }

                }

            }

            return false;

        }


        if (Archives.a('renderMode')==='series'){


            //is this data loaded yet?
            if (Archives.components[id]){

                //do we have the series
                if ((Archives.components[Archives.components[id].top_component_id] && Archives.components[id].level_text !== 'series') || (Archives.components[id].level_text === 'series') ){


                    if (Archives.components[id].level_text === 'series'){
                        var thisSeriesId = id;
                    }else{
                        var thisSeriesId = Archives.components[Archives.components[id].top_component_id].id;
                    }

                    //is the series ready?
                    if (Archives.allSeries.get(thisSeriesId).get('ready')){


                        //is it active?
                        if (parseInt(Archives.a('activeSeries')) === parseInt(thisSeriesId)){


                            //does the component exist?
                            if ($("#c"+id).length > 0){
                                highlightComponent(id);
                                window.clearInterval(Archives.allRoutes.navTimeout);
                                return true;
                            }




                        }else{
                            //is it ready?
                            if (Archives.allSeries.get(thisSeriesId).get('ready')){

                                //render it
                                Archives.allSeries.get(thisSeriesId).view.render();
                            }
                        }

                    }




                }else{

                    console.error("Could not locate the series for this component. Looking for",Archives.components[Archives.components[id].top_component_id],Archives.components[id]);
                    window.clearInterval(Archives.allRoutes.navTimeout);
                    return true;

                }


            }



        }

    }

    function highlightComponent(id){
        if (Archives.components[id].level_text === 'series' || Archives.components[id].level_text === 'subseries'){
            if (Archives.a('domInsertComplete')){

                window.setTimeout(function(){

                    Archives.eventAgg.trigger("navSide:activateNavItem",id);

                },1000);
                

            }else{
                return false;
            }
        }else{
            $("html, body").animate({ scrollTop: $("#c"+id).offset().top - 400}, "fast");
            $("#c"+id).addClass("search-highlight");
        }
    }



}).call(this);