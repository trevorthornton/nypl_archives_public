
/*  NYPL Archives Platform
//  
//  viz.js
//
//  
//  The demo network of topics used for the DH2013 poster
//
*/

(function() {



    "use strict";



	window.Archives.viz = {

		Archives: window.Archives,

		intitalized: false,

		titleOccurrences: [],
		titleNodes: null,
		titleEdges: null,



		init: function(){

			self = this;

			//test if we can do this
			if(!document.createElementNS || !document.createElementNS('http://www.w3.org/2000/svg','svg').createSVGRect){

				return false;
				//alert('We\'re Sorry, this visualization uses the SVG standard, most modern browsers support SVG. If you would like to see this visualization please view this page in another browser such as Google Chrome, Firefox, Safari, or Internet Explorer 9+');	
			}

			//try to dynamically load the d3 library

			$.getScript("/assets/d3.v3.js", function(data, textStatus, jqxhr) {


				$("#collection-content-viz button").click(function(){


					$("#collection-content-viz svg").remove();

				   	$("#collection-content-viz").fadeOut('fast',function(){
				   		$("#collection-overview").fadeIn('fast', function(){
				   		});
				   	});	


				});

			   if (textStatus === 'success'){

			   	console.log('Load was performed.');

			   	$(window).resize(function(){
			   		$("#collection-content-viz")
			   			.css("height", $(window).height() - $("#nypl-header").height() - $(".navbar-inner").first().height())
			   			.css("width", $(window).width());

			   	});		   	
			   	$(window).resize();	

			   	$("#collection-overview, #collection-detailed").fadeOut('fast',function(){
			   		$("#collection-content-viz .status").html('<br><br>Working!');
			   		$("#collection-content-viz").fadeIn('fast', function(){
			   		});
			   	});		   	


			   	window.setTimeout(function(){

				   		self.intitalized = true;

				   		self.buildTitleIndex();

			   	}, 1000);


			   }else{

			   		console.error("could not load d3");
			   }
			});






		},


		buildTitleIndex: function(){


			var self = this;

			//first load all the titles into a large string

			var allTitles = '';
			var titleIndex = [], titleIndexCount = [], titleIndexLookup = [];
			var countThreshold = 2;
			var occurrences = {};

			if (this.Archives.componentCount > 1000){countThreshold = 4;}
			if (this.Archives.componentCount > 3000){countThreshold = 6;}
			if (this.Archives.componentCount > 5000){countThreshold = 8;}

			var progress = 0;
			//useing modern for loops, if they have SVG then its a modern browser
			for (var aElement in this.Archives.components){

				var element = this.Archives.components[aElement];


				/*
				if (++progress % 25 === 0){
					console.log('yes');
					window.setTimeout(function(){$("#collection-content-viz").html('<br><br>Building Concepts ' + progress);	},10);
								
				}
				*/

				if (element.title){
				  allTitles = allTitles + ' ' + element.title + ' ';

				}
				if (element.extentStatement){
				  allTitles = allTitles + ' ' + element.extentStatement + ' ';
				}
				if (element.scopecontent){
				  if (element.scopecontent[0].value){
				    allTitles = allTitles + ' ' + element.scopecontent[0].value + ' ';
				  }
				}
				if (element.unitid){
				  if (element.unitid[0].value){
				    allTitles = allTitles + ' ' + element.unitid[0].value + ' ';
				  }
				}
				if (element.abstract){
				  if (element.abstract[0].value){
				    allTitles = allTitles + ' ' + element.abstract[0].value + ' ';
				  }
				}


			}

			for (var aElement in this.Archives.components){

				var element = this.Archives.components[aElement];

				var title = '';


				if (element.title){

				  title = element.title.replace(/[0-9]{4}/g,'').replace(/[\[\]\(\)"“”;:,.\/?\\\-\+\*]/g, '').trim();

				  if (title.replace(/\s+/g,"").length > 3){


				    if (titleIndexLookup.indexOf(title.toLowerCase())===-1){


				   		var count = (allTitles.match(new RegExp(title, 'ig'))||[]).length;

						if (count > countThreshold){
						  titleIndex.push(title);
						  titleIndexLookup.push(title.toLowerCase());
						  titleIndexCount.push(count);
						  //console.log(count,title);

						}
				    }


				    //now try the proper noun extraction
				    var Pn = self.extractProperNouns(title);
				    for (var x in Pn){

				    	if (Pn[x].toLowerCase){


					    	if (titleIndexLookup.indexOf(Pn[x].toLowerCase())===-1){



					    		var count = (allTitles.match(new RegExp(Pn[x], 'ig'))||[]).length;

								if (count > countThreshold){

									var addIt = true;
									//before we add make sure there is not something already in that has this with the exact same number of matches "Craig David interview" vs "Craig David"
									for(var i = 0; i < titleIndex.length; i++){

										if (titleIndex[i].search(Pn[x]) !== -1 && titleIndexCount[i] === count){
											addIt = false;
										}
									}

									if (addIt){
										titleIndex.push(Pn[x]);
										titleIndexLookup.push(Pn[x].toLowerCase());
										titleIndexCount.push(count);
										//console.log(count,'@' + Pn[x]);
									}

								}

					    	}
					    }

				    }


				  }

				}


			}

			/*
			var sum = 0;
			for(var i = 0; i < titleIndexCount.length; i++){
			  sum += parseInt(titleIndexCount[i]);
			}

			var avg = sum/titleIndexCount.length;
			*/



			console.log('Starting occurrences building');


			for (var aElement in this.Archives.components){

				var element = this.Archives.components[aElement];

				var allTitles = '';


				if (element.title){
				  allTitles = allTitles + ' ' + element.title + ' ';

				}
				if (element.extentStatement){
				  allTitles = allTitles + ' ' + element.extentStatement + ' ';
				}
				if (element.scopecontent){
				  if (element.scopecontent[0].value){
				    allTitles = allTitles + ' ' + element.scopecontent[0].value + ' ';
				  }
				}
				if (element.unitid){
				  if (element.unitid[0].value){
				    allTitles = allTitles + ' ' + element.unitid[0].value + ' ';
				  }
				}
				if (element.abstract){
				  if (element.abstract[0].value){
				    allTitles = allTitles + ' ' + element.abstract[0].value + ' ';
				  }
				}

				if (this.Archives.components[aElement].title){
					for (var y in titleIndex){

						if (titleIndex[y].toLowerCase){


							if (allTitles.toLowerCase().search(titleIndex[y].toLowerCase()) !== -1){
								if (occurrences[titleIndex[y]]){
									occurrences[titleIndex[y]].push(this.Archives.components[aElement].id);
								}else{
									occurrences[titleIndex[y]] = [this.Archives.components[aElement].id];
								}
							}
						}
					}
				}
			}





			//console.log(occurrences);

			this.titleOccurrences = occurrences;


			this.buildTitleIndexNetwork();


		},


		buildTitleIndexNetwork: function(){


			var nodes = [], edges = [];

			var nodesAdded = [];


			var index = -1;

			for (var i in this.titleOccurrences){

				//first off add the concept to the nodes
				nodes.push({index: ++index, x: 0, y: 0, title: i, weight: 1, count: this.titleOccurrences[i].length, type: 'concept'});


				var conceptId = index;

				for (var x in this.titleOccurrences[i]){

					var element = this.Archives.components[this.titleOccurrences[i][x]];

					if (element){
						if (element.level_text){

							//we don't want series
							if (element.level_text != 'series'){

								//if the node parent is fairly small then add it instead, it will make a simpler graph
								if (this.Archives.components[element.parent_id]){

									if (this.Archives.components[element.parent_id].total_children <= 30 && this.Archives.components[element.parent_id].level_text !== 'series'){

										//not yet added
										if (nodesAdded.indexOf(this.Archives.components[element.parent_id].id) === -1){
											nodes.push({index: ++index, x: 0, y: 0, weight: 1, count: this.Archives.components[element.parent_id].total_children,  cId: this.Archives.components[element.parent_id].id, title: this.Archives.components[element.parent_id].title, type: 'folder'});
											//link it to the concept
											edges.push({source: index, target: conceptId});
											nodesAdded.push(this.Archives.components[element.parent_id].id);
										}else{

											//already in there find it and add a link to this concept
											for (var y in nodes){
												if (nodes[y].cId === this.Archives.components[element.parent_id].id){
													edges.push({source: nodes[y].index, target: conceptId});	
													break;
												}
											}

										}

									}else{


										//just add the compoent
										//not yet added

										if (nodesAdded.indexOf(element.id) === -1){
											nodes.push({index: ++index, x: 0, y: 0, weight: 1, count: 1, cId: element.id, title: element.title, type: 'component'});
											//link it to the concept
											edges.push({source: index, target: conceptId});
											nodesAdded.push(element.id);
										}else{

											//already in there find it and add a link to this concept
											for (var y in nodes){
												if (nodes[y].cId === element.id){
													edges.push({source: nodes[y].index, target: conceptId});	
													break;
												}
											}

										}

									}


								}else{

									if (nodesAdded.indexOf(element.id) === -1){
										nodes.push({index: ++index, x: 0, y: 0, weight: 1, count: 1, cId: element.id, title: element.title, type: 'component'});
										//link it to the concept
										edges.push({source: index, target: conceptId});
										nodesAdded.push(element.id);
									}else{

										//already in there find it and add a link to this concept
										for (var y in nodes){
											if (nodes[y].cId === element.id){
												edges.push({source: nodes[y].index, target: conceptId});	
												break;
											}
										}

									}

								}

							}

						}
					}


				}


			}

			var weights = {};

			for (var x in edges){


				if (typeof weights[edges[x].source] === 'number'){
					weights[edges[x].source] = weights[edges[x].source] + 1;
				}else{
					weights[edges[x].source]=1;
				}

				if (typeof weights[edges[x].target] === 'number'){
					weights[edges[x].target] = weights[edges[x].target] + 1;
				}else{
					weights[edges[x].target]=1;
				}

			}
			var avg = 0;
			var count = 0;
			for (var x in weights){
				avg = avg + weights[x];
				count++;
			}

			avg = ~~(avg/count);
			//avg = avg - 1;

			console.log("Before trim avg: ", avg, "Nodes: ", nodes.length, " edges: ", edges.length);

			if (nodes.length > 600){

				var remove = [];
				for (var x in weights){
					if (parseInt(weights[x]) < avg){
						remove.push(parseInt(x));
					}
				}

				var newNodes = [];
				var newEdges = [];

				console.log(remove);
				for (var x in nodes){
					if (remove.indexOf(nodes[x].index) === -1){
						newNodes.push(nodes[x]);
					}				
				}

				for (var x in edges){
					if (remove.indexOf(edges[x].target) === -1 && remove.indexOf(edges[x].source) === -1){
						newEdges.push(edges[x]);
					}				
				}



				//now we have to rebuild the indexes
				var count=-1;
				var oldIndexes = {};
				for (var x in newNodes){
					oldIndexes[String(newNodes[x].index)] = ++count;
					newNodes[x].index = count;
				}
				for (var x in newEdges){
					newEdges[x].target = parseInt(oldIndexes[String(newEdges[x].target)]);
					newEdges[x].source = parseInt(oldIndexes[String(newEdges[x].source)]);
				}


				nodes = newNodes;
				edges = newEdges;

			}


			console.log("After trim Nodes: ", nodes.length, " edges: ", edges.length);

			this.titleNodes = nodes;
			this.titleEdges = edges;


			this.titleRenderGraph();

		},


		titleRenderGraph: function(){


			var tooltip = d3.select("body")
				.append("div")
				.attr('class','d3ToolTip');


			$("#collection-content-viz .status").text('');
			var width = $("#collection-content-viz").width(),
			    height = $("#collection-content-viz").height();


			for (var x in this.titleNodes){
				this.titleNodes[x].x = width/2;
				this.titleNodes[x].y = height/2;


			}
			var color = d3.scale.category20();

			var force = d3.layout.force()
			    .charge(-950)
			    .linkDistance(70)
			    .gravity(0.3)
			    .size([width, height]);

			var svg = d3.select("#collection-content-viz").append("svg")
			    .attr("width", width)
			    .attr("height", height);

			     svg.append("rect")
			        .attr("width", "100%")
			        .attr("height", "100%")
			        .style("fill","whitesmoke")
			        .call(d3.behavior.zoom()
			          .on("zoom", function() {

			            svg.attr("transform", "translate(" + d3.event.translate + 
			              ")scale(" + d3.event.scale + ")");
			          }));

			    svg = svg.append("g");

			    /*
			    .call(d3.behavior.zoom() 

				  .on("zoom", function() { 
					svg.attr("transform", "translate(" + [d3.event.translate[0]+400,d3.event.translate[1]+100] + 

					 ")scale(" + d3.event.scale*.4 + ")"); 
	 			  })); 		
				
			svg.append("rect")
				.attr("width", width)
				.attr("height", height);
				

				  

			svg = svg.append("g"); */

			for (var n in this.titleNodes){

				console.log(this.titleNodes[n]);

			}


			 force.nodes(this.titleNodes);
			 force.links(this.titleEdges);

			 force.start();




			var link = svg.selectAll(".link")
			  .data(this.titleEdges)
			.enter().append("line")
			  .attr("class", "link")
			  .style("stroke-width", function(d) { return Math.sqrt(d.value); });


	/*
			var node = svg.selectAll(".node")
			  .data(this.titleNodes)
			.enter().append("circle")
			  .attr("class", "node")
			  .attr("r", function(d) { return useSize(d.count)})
			  .style("fill", function(d) { return useColor(d.type); })
			  .call(force.drag);

			  */

	   		var node = svg.selectAll(".node")
	          .data(this.titleNodes)
	          .enter().append("g")
			  .style("cursor","pointer")
			  .attr("id",function(d){ return "aNode" + d.id })

			  .on("mouseover", function(d){ 
			  	tooltip.style("visibility", "visible");   
			  	tooltip.html(d.title)
			  })
				.on("mousemove", function(d){

					return tooltip.style("top", (d3.event.pageY-10)+"px").style("left",(d3.event.pageX+10)+"px");

				})
				.on("mouseout", function(d){

					tooltip.style("visibility", "hidden");
				})
			  /*
			  
				
					
					
					
					inSituTimeOutIsOn = true;
					clearTimeout(inSituTimeOut);
					inSituTimeOut = setTimeout(function(){
						
						if (inSituTimeOutIsOn){
							
							//do not filter if we are useing the left interface
							if (inSituFilter.length == 0){
								
								//another check
								if (!usingMenuFilter){
									tooltip.style("visibility", "hidden");
									inSituFilter.push(d.id);
									filterInSitu();
									toggleLabels(true);
								}
							}
							
												
							
						}
					},2000);
					
					
				})
				.on("mousemove", function(d){
					
					return tooltip.style("top", (d3.event.pageY-10)+"px").style("left",(d3.event.pageX+10)+"px");

				})
				.on("mouseout", function(d){
					
					
					clearTimeout(inSituTimeOut);
					inSituTimeOutIsOn = false;
					tooltip.style("visibility", "hidden");
					
					//if thie one is in the filter then clear the filter
					if (!usingMenuFilter){
						
						if (inSituFilter.indexOf(d.id) != -1){
							inSituFilter.splice(inSituFilter.indexOf(d.id),1);
						}
						
						if (inSituFilter.length == 0){
							filterInSitu();
							toggleLabels(false);
						}
					}
					
					
				})	
			   .on("dblclick",function(d){ window.open("node/" + d.id)  })	
			  */
	          .attr("class", "node");	

			node.append("rect")
				.style("fill","whitesmoke")
				.style("stroke","none")
				.attr("x", function(d) { return useSize(d.count) * 5 / 2 * -1 })
				.attr("y", function(d) { return useSize(d.count) * 6 / 2 * -1 })
				.attr("width", function(d) { 


					if (d.type==='component'){
						return useSize(d.count) * 5;
					}

					return 0;

				})
				.attr("height", function(d) { 


					if (d.type==='component'){
						return useSize(d.count) * 6;
					}

					return 0;

				});  


			node
			.append("svg:path")
				.attr("id",  function(d) { return "aNodePath" + d.id})
				.attr("class",  function(d) { return "aNodePath_" + d.type})
				.attr("transform", function(d) {


							if (d.type=='folder'){
								var nodeSize = useSize(d.count) / 6; 
								return "translate(" + ((nodeSize * 25) *-1) + "," + ((nodeSize * 25) * -1) + ")scale(" + nodeSize + ")";				
							}

							if (d.type=='concept'){
								var nodeSize = useSize(d.count) / 8; 
								return "translate(" + ((nodeSize * 25) *-1) + "," + ((nodeSize * 25) * -1) + ")scale(" + nodeSize + ")";				
							}

							if (d.type=='component'){
								var nodeSize = useSize(d.count) / 6; 
								return "translate(" + ((nodeSize * 25) *-1) + "," + ((nodeSize * 25) * -1) + ")scale(" + nodeSize + ")";				
							}

					})	
				.style("fill",function(d){

					return useColor(d.type);
				})
				.style("stroke",function(d){

						if (d.type=='concept'){
							return "whitesmoke"
						}
						return "none";

				})
				.style("stroke-width",function(d){
						if (d.type=='concept'){
							return "1px"
						}			
						return "none";

				})			
				.attr("d",function(d){

	 				if (d.type=='concept'){
						return "M3.872,37.62c0.721,0.8,3.536,1.902,4.777,1.902c2.005,0,3.809-0.863,5.059-2.239 c2.217,1.575,4.925,2.504,7.852,2.504c4.217,0,7.984-1.923,10.475-4.939c1.133,0.307,2.32,0.472,3.55,0.472 c7.499,0.001,13.579-6.077,13.579-13.577c0-5.822-3.665-10.787-8.812-12.716c-1.933-5.148-6.896-8.812-12.718-8.812 c-4.848,0-9.099,2.542-11.502,6.365c-0.563-0.071-1.135-0.112-1.718-0.112c-7.499,0-13.578,6.079-13.578,13.579 c0,3.043,1.001,5.854,2.692,8.117c-1.065,1.205-1.713,2.788-1.713,4.524C1.815,33.942,2.054,36.587,3.872,37.62";
					}else if (d.type ==='folder'){
						return 'M15.984,21.382c-1.263-0.632-5.573-2.872-8.098-4.186l9.67,12.473v-6.873 C17.554,22.797,17.453,22.117,15.984,21.382z M45.164,6.888l0.014-0.052l-11.318-5.66c-0.141-0.061-0.646-0.258-1.271-0.258 c-0.416,0-0.789,0.085-1.139,0.259L5.84,13.982c-0.93,0.464-1.043,1.296-1.059,1.497v25.609c0,0.583,0.413,1.022,0.731,1.275 l-0.014,0.052l11.316,5.659c0.098,0.044,0.622,0.26,1.274,0.26c0.417,0,0.79-0.086,1.139-0.26l25.609-12.806 c0.93-0.465,1.045-1.296,1.059-1.497V8.163C45.895,7.581,45.482,7.141,45.164,6.888z M12.207,41.363 c-0.702,0.216-1.626-0.612-1.991-1.761c-0.194-0.612-0.22-1.231-0.073-1.742c0.075-0.257,0.262-0.71,0.685-0.843 c0.076-0.024,0.157-0.036,0.24-0.036c0.673,0,1.425,0.772,1.749,1.798C13.191,39.955,12.911,41.139,12.207,41.363z M44.828,18.073 L18.485,31.315v15.261c0,0.257-0.208,0.465-0.464,0.465c-0.257,0-0.464-0.209-0.464-0.465V31.188l-11.706-15.1 c-0.134-0.172-0.129-0.414,0.011-0.582c0.141-0.168,0.379-0.214,0.572-0.114c0.082,0.043,8.161,4.258,9.966,5.16 c0.824,0.413,1.32,0.839,1.622,1.21c0.302-0.371,0.797-0.798,1.622-1.21c1.811-0.906,24.365-11.848,24.591-11.958 c0.229-0.112,0.508-0.016,0.621,0.215c0.111,0.231,0.016,0.508-0.215,0.621c-0.229,0.11-22.777,11.05-24.583,11.954 c-1.422,0.711-1.562,1.368-1.573,1.43v7.463l25.927-13.033c0.229-0.114,0.508-0.024,0.623,0.207 C45.15,17.678,45.059,17.958,44.828,18.073z';
					}else{
						return 'M44.788,42.693l-3.244-18.12l2.459-18.237L38.14,5.546l-0.75-4.194L24.34,3.687l-13.134-1.77l-0.274,2.032 L8.245,3.95l0.001,2.617L4.818,7.181l3.24,18.113L5.603,43.542l2.666,0.359l0.001,2.045l3.483-0.001l0.461,2.578l13.036-2.334 l13.143,1.771l0.273-2.03l2.691-0.001l-0.001-2.622L44.788,42.693z M6.862,8.604l1.384-0.249l0.005,8.016L6.862,8.604z M7.583,42.031l0.682-5.063l0.004,5.156L7.583,42.031z M42.021,7.847l-0.507,3.774l-2.784-2.787l-0.265-1.466L42.021,7.847z M38.335,10.949l-4.002,0.002l-0.002-4.007L38.335,10.949z M35.965,3.396l0.341,1.903l-1.282-0.173l-1.325-1.325L35.965,3.396z M13.639,46.479l-0.095-0.534l3.097-0.002L13.639,46.479z M10.03,44.186L10.007,5.711l22.562-0.015l0.003,7.018l7.007-0.005 l0.019,31.458L10.03,44.186z M41.354,33.501l1.39,7.768l-1.386,0.25L41.354,33.501z M36.109,14.989l-22.347,0.015l0.001,1.761 l22.346-0.014V14.989z M36.112,19.796L13.765,19.81l0.002,1.761l22.346-0.013L36.112,19.796z M36.114,24.604l-22.346,0.014 l0.001,1.762l22.348-0.014L36.114,24.604z M36.119,29.408l-22.348,0.015l0.002,1.762l22.346-0.014V29.408z M13.774,34.231 l0.001,1.762l22.346-0.014v-1.762L13.774,34.231z';
					}

				});

				node.append("svg:text")
					.style("fill", function(d) {


						return 'white';

					})
					.style("stroke", function(d) {

						if (d.type==='folder'){
							return 'none';
						}
						return 'black';
					})
					.style("stroke-width","0.1px")


					.attr("transform", function(d) {

						if (d.type==='folder'){
							return "translate(" + (useSize(d.count) - 4)  * -1 + "," + useSize(d.count) * 2 * -1 + ")rotate(-30)";
						}

					})

					.text(function(d){ 


						if (d.title){
							if (d.type==='folder'){
								return d.title.substr(0,10);
							}

							return d.title;
						}else{
							return "";
						}

					 })
					.attr("text-anchor", "middle")
					.attr("display", function(d) { 
						if (d.type === "concept" || d.type==='folder'){
							return "block";	
						}else{
							return "none";
						}
					})
					.attr("font-size", function(d) { 

							if (d.type == "concept"){

								return useSize(d.count);

							}
							if (d.type == "folder"){

								return useSize(d.count) / 1.5;

							}

					}); 
			//node.append("title")
			//  .text(function(d) { return d.title; });

			force.on("tick", function() {

				if (force.alpha() < 0.025){

					link.attr("x1", function(d) { return d.source.x; })
					    .attr("y1", function(d) { return d.source.y; })
					    .attr("x2", function(d) { return d.target.x; })
					    .attr("y2", function(d) { return d.target.y; });

					svg.selectAll("g.node")
						.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")";});
						//.attr("visibility",function(d) { if (d.vis){return 'visible'}else{ return 'hidden'}}); 

					//node.attr("x", function(d) { return d.x; })
					  //  .attr("y", function(d) { return d.y; });
				}
			});

			function useSize(count){

				var size = Math.sqrt(count);

				if (size < 2){size = 2;}
				if (size > 15){size = 15;}

				return size;
			}

			function useColor(type){
				switch (type){
					case 'concept':
						return '#3498db';
					case 'folder':
						return "#2c3e50";
					case 'component':
						return "#f39c12";
				}			

				return "#2ecc71";
			}


		},



		extractProperNouns: function(word){



			var words = word.split(' ');

			var lastFoundWord = '';

			var okayPrepositions = ['of', 'del', 'de', 'the', 'des'];
			var allFoundWord = [];


			for (var w in words){			
				var aWord = words[w];
				var foundWord = '';

				//this whole thing is just looking for a repition of caplitilized words, probably could be implemmented in one regex statement or something....


				//is it capitalized?
				if (aWord[0]){
					if (aWord[0] === aWord[0].toUpperCase()){					
						foundWord = aWord;
						//it is look into the future words (5)
						for(var i = 1; i < 6; i++){
							if (words[parseInt(w)+parseInt(i)]){
								if (okayPrepositions.indexOf(words[parseInt(w)+parseInt(i)].toLowerCase()) !== -1){
									foundWord += ' ' + words[parseInt(w)+parseInt(i)];
								}else{
									if (words[parseInt(w)+parseInt(i)][0]){
										if (words[parseInt(w)+parseInt(i)][0] === words[parseInt(w)+parseInt(i)][0].toUpperCase()){
											foundWord += ' ' + words[parseInt(w)+parseInt(i)];
										}else{
											break;									
										}
									}
								}
							}else{
								break;							
							}

						}

						//make sure it is not just a smaller part of the previous found word
						if (lastFoundWord.search(foundWord) === -1 && foundWord.split(' ').length > 1){


							var prepCheckSkip = true;

							if (okayPrepositions.indexOf(foundWord.split(' ')[foundWord.split(' ').length-1].toLowerCase()) === -1){ prepCheckSkip = false; }


							if (!prepCheckSkip){

								//console.log("found word", foundWord, " | ", word);
								allFoundWord.push(foundWord);

								lastFoundWord = foundWord;


							}

						}else{

							//console.log("Not Using: ", foundWord, " | ", word);

						}


					}
				}	


			}


			
			return allFoundWord;

		},





			// :( things don't work
			networkExtractNames: function(){


				this.controledTerms = {};


				var regexPersonalNameComma = new RegExp(/([A-Z]{1}[a-z]*),\s([A-Z]{1}[a-z]*)[\s|,]/);


				_.each(this.components, function(element, index, list){

				var personName = regexPersonalNameComma.exec(element.title);

				if (personName){

				  console.log(personName);

				}


				});





			}


	}



}).call(this);

