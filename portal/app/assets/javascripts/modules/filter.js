/*  NYPL Archives Platform
//  
//  viewDigitalAssets.js
//
//  This view controls the displaying of digital assets
//  The trigger to preview digital assets (hover) is taken care of in the window view to allow event delegation
//
*/

(function() {

    "use strict";


    window.Archives.filter = {


        isFiltered: false,

        parentCount : {},


        //SEARCH
        searchData: function(searchTerm){

          var self =this;

          if (Archives.debug)
            console.log("Filtering ", searchTerm);


          if (searchTerm.length<3){
          	Archives.eventAgg.trigger("navFilter:searchError", 'Term too short', this);    
            return false;
          }


          var compoenentsAdded = [],
              isDateSearch = false,
              searchTermLower = searchTerm.toLowerCase(),
              newCompoenents = {},
              hasResults = false;


          this.parentCount = {}

          var dateRegex = /([0-9]{4})\-([0-9]{4})|([0-9]{4})/;
          

          if (dateRegex.exec(searchTerm)){
            isDateSearch=true;

            var r = dateRegex.exec(searchTerm)[0];

            if (r.search('-') !== -1){
              var date1 = r.split('-')[0];
              var date2 = r.split('-')[1];
            }else{
              var date1 = r;
              var date2 = r;
            }

            if (this.debug)
              console.log(date1,date2);

          }else{


            var searchTermLowerRegex = searchTermLower.replace(/\s/g,'.*');
            //console.log(searchTermLower);

          }




          _.each(Archives.components, function(element, index, list){


            //strip out and previous search results
            if (element.title){
              element.title = element.title.replace('</span>','');
              element.title = element.title.replace('<span class="search-highlight">','');
            }
            if (element.extent_statement){
              element.extent_statement = element.extent_statement.replace('</span>','');
              element.extent_statement = element.extent_statement.replace('<span class="search-highlight">','');
            }
            if (element.scopecontent){
              if (element.scopecontent[0].value){
                element.scopecontent[0].value = element.scopecontent[0].value.replace('</span>','');
                element.scopecontent[0].value = element.scopecontent[0].value.replace('<span class="search-highlight">','');
              }
            }
            if (element.unitid){
              if (element.unitid[0].value){
                element.unitid[0].value = element.unitid[0].value.replace('</span>','');
                element.unitid[0].value = element.unitid[0].value.replace('<span class="search-highlight">','');
              }
            }
            if (element.abstract){
              if (element.abstract[0].value){
                element.abstract[0].value = element.abstract[0].value.replace('</span>','');
                element.abstract[0].value = element.abstract[0].value.replace('<span class="search-highlight">','');
              }
            }
            if (element.origination){
              if (element.origination[0].value){
                element.origination[0].value = element.origination[0].value.replace('</span>','');
                element.origination[0].value = element.origination[0].value.replace('<span class="search-highlight">','');
              }
            }

            var add=false;



            if (!isDateSearch){

              var rangeFrom = 0, rangeTo = 0;
              //var tempString

              if (element.title){
                if (element.title.toLowerCase().search(searchTermLower) != -1){ 
                  
                  rangeFrom = element.title.toLowerCase().search(searchTermLower);
                  rangeTo = searchTermLower.length;
                  add = true;


                  element.title = element.title.replace('</span>','');
                  element.title = element.title.replace('<span class="search-highlight">','');

                  element.title = element.title.insertAt(rangeFrom+rangeTo,'</span>');
                  element.title = element.title.insertAt(rangeFrom,'<span class="search-highlight">');
                 

                }
                //also do greedy regex search
                if (element.title.toLowerCase().search(searchTermLowerRegex) != -1 && add===false){ 

                  rangeFrom = element.title.toLowerCase().search(searchTermLowerRegex);
                  rangeTo = searchTermLower.length;
                  add = true;
                  element.title = element.title.replace('</span>','');
                  element.title = element.title.replace('<span class="search-highlight">','');

                  element.title = element.title.insertAt(rangeFrom+rangeTo,'</span>');
                  element.title = element.title.insertAt(rangeFrom,'<span class="search-highlight">');

                }
              }
              if (element.extent_statement){
                if (element.extent_statement.toLowerCase().search(searchTermLower) != -1){ 
                              
                  rangeFrom = element.extent_statement.toLowerCase().search(searchTermLower);
                  rangeTo = searchTermLower.length;
                  add = true;

                  element.extent_statement = element.extent_statement.replace('</span>','');
                  element.extent_statement = element.extent_statement.replace('<span class="search-highlight">','');
                  element.extent_statement = element.extent_statement.insertAt(rangeFrom+rangeTo,'</span>');
                  element.extent_statement = element.extent_statement.insertAt(rangeFrom,'<span class="search-highlight">');

                }
                if (element.extent_statement.toLowerCase().search(searchTermLowerRegex) != -1 && add===false){ 
                  
                  rangeFrom = element.extentStatement.toLowerCase().search(searchTermLowerRegex);
                  rangeTo = searchTermLower.length;
                  add = true;
                  element.extent_statement = element.extent_statement.replace('</span>','');
                  element.extent_statement = element.extent_statement.replace('<span class="search-highlight">','');
                  element.extent_statement = element.extent_statement.insertAt(rangeFrom+rangeTo,'</span>');
                  element.extent_statement = element.extent_statement.insertAt(rangeFrom,'<span class="search-highlight">');    

                }
              }          
              if (element.scopecontent){
                if (element.scopecontent[0].value){
                  if (element.scopecontent[0].value.toLowerCase().search(searchTermLower) != -1){ 
                    
                    rangeFrom = element.scopecontent[0].value.toLowerCase().search(searchTermLower);
                    rangeTo = searchTermLower.length; 
                    add = true;

                    element.scopecontent[0].value = element.scopecontent[0].value.replace('</span>','');
                    element.scopecontent[0].value = element.scopecontent[0].value.replace('<span class="search-highlight">','');
                    element.scopecontent[0].value = element.scopecontent[0].value.insertAt(rangeFrom+rangeTo,'</span>');
                    element.scopecontent[0].value = element.scopecontent[0].value.insertAt(rangeFrom,'<span class="search-highlight">');      

                  }
                  if (element.scopecontent[0].value.toLowerCase().search(searchTermLowerRegex) != -1 && add===false){ 
                    
                    rangeFrom = element.scopecontent[0].value.toLowerCase().search(searchTermLowerRegex);
                    rangeTo = searchTermLower.length; 
                    add = true;
                    element.scopecontent[0].value = element.scopecontent[0].value.replace('</span>','');
                    element.scopecontent[0].value = element.scopecontent[0].value.replace('<span class="search-highlight">','');
                    element.scopecontent[0].value = element.scopecontent[0].value.insertAt(rangeFrom+rangeTo,'</span>');
                    element.scopecontent[0].value = element.scopecontent[0].value.insertAt(rangeFrom,'<span class="search-highlight">');    

                  }
                }
              }          
              if (element.unitid){
                if (element.unitid[0].value){
                  if (element.unitid[0].value.toLowerCase().search(searchTermLower) != -1){ 
                    rangeFrom = element.unitid[0].value.toLowerCase().search(searchTermLower);
                    rangeTo = searchTermLower.length; 
                    add = true;

                    element.unitid[0].value = element.unitid[0].value.replace('</span>','');
                    element.unitid[0].value = element.unitid[0].value.replace('<span class="search-highlight">','');
                    element.unitid[0].value = element.unitid[0].value.insertAt(rangeFrom+rangeTo,'</span>');
                    element.unitid[0].value = element.unitid[0].value.insertAt(rangeFrom,'<span class="search-highlight">');


                  }
                  if (element.unitid[0].value.toLowerCase().search(searchTermLowerRegex) != -1 && add===false){ 
                    

                    rangeFrom = element.unitid[0].value.toLowerCase().search(searchTermLowerRegex);
                    rangeTo = searchTermLower.length; 
                    element.unitid[0].value = element.unitid[0].value.replace('</span>','');
                    element.unitid[0].value = element.unitid[0].value.replace('<span class="search-highlight">','');
                    element.unitid[0].value = element.unitid[0].value.insertAt(rangeFrom+rangeTo,'</span>');
                    element.unitid[0].value = element.unitid[0].value.insertAt(rangeFrom,'<span class="search-highlight">');


                    add = true;

                  }
                }
              }    
              if (element.abstract){
                if (element.abstract[0].value){
                  if (element.abstract[0].value.toLowerCase().search(searchTermLower) != -1){ 
                    rangeFrom = element.abstract[0].value.toLowerCase().search(searchTermLower);
                    rangeTo = searchTermLower.length; 
                    add = true;

                    element.abstract[0].value = element.abstract[0].value.replace('</span>','');
                    element.abstract[0].value = element.abstract[0].value.replace('<span class="search-highlight">','');
                    element.abstract[0].value = element.abstract[0].value.insertAt(rangeFrom+rangeTo,'</span>');
                    element.abstract[0].value = element.abstract[0].value.insertAt(rangeFrom,'<span class="search-highlight">');


                  }
                  if (element.abstract[0].value.toLowerCase().search(searchTermLowerRegex) != -1 && add===false){ 
                    

                    rangeFrom = element.abstract[0].value.toLowerCase().search(searchTermLowerRegex);
                    rangeTo = searchTermLower.length; 

                    element.abstract[0].value = element.abstract[0].value.replace('</span>','');
                    element.abstract[0].value = element.abstract[0].value.replace('<span class="search-highlight">','');

                    element.abstract[0].value = element.abstract[0].value.insertAt(rangeFrom+rangeTo,'</span>');
                    element.abstract[0].value = element.abstract[0].value.insertAt(rangeFrom,'<span class="search-highlight">');


                    add = true;

                  }
                }
              }   
              if (element.origination){
                if (element.origination[0].value){
                  if (element.origination[0].value.toLowerCase().search(searchTermLower) != -1){ 
                    rangeFrom = element.origination[0].value.toLowerCase().search(searchTermLower);
                    rangeTo = searchTermLower.length; 
                    add = true;

                    element.origination[0].value = element.origination[0].value.replace('</span>','');
                    element.origination[0].value = element.origination[0].value.replace('<span class="search-highlight">','');
                    element.origination[0].value = element.origination[0].value.insertAt(rangeFrom+rangeTo,'</span>');
                    element.origination[0].value = element.origination[0].value.insertAt(rangeFrom,'<span class="search-highlight">');


                  }
                  if (element.origination[0].value.toLowerCase().search(searchTermLowerRegex) != -1 && add===false){ 
                    

                    rangeFrom = element.origination[0].value.toLowerCase().search(searchTermLowerRegex);
                    rangeTo = searchTermLower.length; 

                    element.origination[0].value = element.origination[0].value.replace('</span>','');
                    element.origination[0].value = element.origination[0].value.replace('<span class="search-highlight">','');

                    element.origination[0].value = element.origination[0].value.insertAt(rangeFrom+rangeTo,'</span>');
                    element.origination[0].value = element.origination[0].value.insertAt(rangeFrom,'<span class="search-highlight">');


                    add = true;

                  }
                }
              }           




            }else{


              if (!element.date_inclusive_start || !element.date_inclusive_end){

                //no date_inclusive statements, but is there a year in the date_statement?

                if (element.date_statement){



                  if (element.date_statement.search(/[0-9]{4}/) !== -1){

                    //var date = element.date_statement.substring(element.date_statement.search(/[0-9]{4}/),4);
                    //console.log(element.date_statement,date);
                    var date = element.date_statement.match( /[0-9]{4}/gm );
                    if (date){
                      

                      if (date1 !== date2){

                        if ( parseInt(date) <= parseInt(date2) && parseInt(date) >=  parseInt(date1)){
                          add = true;
                        }

                        
                      }else{

                        if (parseInt(date) == parseInt(date1) || parseInt(date) == parseInt(date2)){ 
                          add=true;
                        }

                      }


                    }

                  }

                }



              }



              if (element.date_inclusive_start && element.date_inclusive_end){


                if (parseInt(date1) >= parseInt(element.date_inclusive_start) && parseInt(date2) <= (element.date_inclusive_end)){
                  add = true;
                }       



              }



            }


            if(add){

              rangeTo = rangeTo+rangeFrom;

              element.range=[rangeFrom,rangeTo];

              hasResults = true;


              //console.log(element);

              

              //before we add we need to make sure all of it's parents are already added
              if (element.parent_id){



                var lookFor = element.parent_id;

                for (var x = 0; x < 10; x++){

                    

                    if (Archives.components[lookFor]){

                      if (Archives.components[lookFor].level_text === 'series'){
                              //hit the top
                              newCompoenents[String(lookFor)] = Archives.components[lookFor];

                              if (self.parentCount[String(lookFor)]){
                                self.parentCount[String(lookFor)]++;
                              }else{
                                self.parentCount[String(lookFor)] = 1;
                              }

                              break;
                      }

                      //not a series but need to add it anayway, since it is a parent
                      newCompoenents[String(lookFor)] = Archives.components[lookFor];
                      if (self.parentCount[String(lookFor)]){
                        self.parentCount[String(lookFor)]++;
                      }else{
                        self.parentCount[String(lookFor)] = 1;
                      }


                      //setup the next search
                      if (Archives.components[lookFor].parent_id){
                        lookFor = Archives.components[lookFor].parent_id;
                      }else{
                        //end of the line
                        break;
                      }



                    }

                }

              }


              //now add in the search result
              newCompoenents[String(element.id)] = element;


              if (element.level_text === 'series' || element.level_text === 'subseries'){
                if (self.parentCount[String(element.id)]){
                  self.parentCount[String(element.id)]++;
                }else{
                  self.parentCount[String(element.id)] = 1;
                }
              }

              //we might need to add the children of this search result if it is just a heading/subseries
              if (!element.container && element.has_children){

                if (element.child_ids.length <= 10){

                  for (var x = 0; x < element.child_ids.length; x++){
                    newCompoenents[String(element.child_ids[x])] = Archives.components[element.child_ids[x]];
                  }

                  

                }


              }


            }





          });

          if (hasResults){

            this.isFiltered = true;   

            //Chrome sorts it's object, firefox doesn't, who knows what IE does... sort them before returning them should make them in the correct order
            this.searchRender(this.sortObjectByKey(newCompoenents));
                 

            Archives.eventAgg.trigger("navFilter:isFiltered", '', this);    

          }else{
            
          	Archives.eventAgg.trigger("navFilter:searchError", 'No Results', this);    

          }


        },




        searchRender: function(components){

      		var self = this;

      		if (!Archives.onDetailPage){
      		  Archives.allRoutes.trigger("route:showDetailed");  
      		}

              Archives.eventAgg.trigger("navSticky:inTransition", null);
              var htmlAll = '';


      		$("#collection-content-detailed").fadeOut("fast",function(){


                  var htmlAll = '';
                  var templateFunction = _.template(Archives.templates['singleComponent'][Archives.collectionResponse.component_layout_id]);

                  //build a div for each one and render into it
                  _.each(components, function(element, index, list){
                      var margin = (element.level_text === 'series' || element.level_text === 'subseries' ) ? ' margin-' + element.level_text : '';
                      htmlAll += '<div id="c' + element.id + '" class="collection-detailed-row' + margin + '">' + templateFunction({model: element}) + '</div>';
                  });

                  $("#collection-content-searchresults").html(htmlAll);


                  $('#fixed-nav-title').text('Filter Results:');

                  $("#collection-content-searchresults").fadeIn();


                  $(window).scrollTop(0);

                  Archives.navSide.render();

                  Archives.eventAgg.trigger("global:containerListChanged", null, this);


      		});



        },

        sortObjectByKey : function(obj){
            var keys = [];
            var sortedObj = {};

            for(var key in obj){
                if(obj.hasOwnProperty(key)){
                    keys.push(key);
                }
            }

            // sort keys
            keys.sort();

            // create new array based on Sorted Keys
            jQuery.each(keys, function(i, key){
                sortedObj[key] = obj[key];
            });

            return sortedObj;

        }
        

    }

}).call(this);