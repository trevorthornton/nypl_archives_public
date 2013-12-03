window.Archives.templates['skeleton'] = """
       
		

		<% if (typeof model.type === 'undefined' || model.type !== 'Collection') { %>
			<% counter.count++ %>

			<%
				
				if ((counter.count === 0 || counter.count % Archives.a('componentsPerPass') === 0) && Archives.a('useGroupingRender')){

					if (counter.count !== 0){
						%> 
						</div>
						<%
					} 
					%>
					<div class="collection-detailed-block">
					<%
				}
			%>



		    <div id="c<%=model.id%>" class="collection-detailed-row<%=  (model.level_text === 'series' || model.level_text === 'subseries' ) ? ' margin-' + model.level_text : ''%>">
		    

		      <%=templateComponentFunction({model : model})%>
		    
		    </div>  




		<% } %>


	    <% if (typeof model.components !== 'undefined') { %>
	   
	      <% _.each(model.components, function(child) { %>
	          <%= templateFunction({model: child, templateFunction: templateFunction, templateComponentFunction: templateComponentFunction, counter: counter}) %>
	      <% }); %>


	    <% }else{ %>
	    
	      

	      <% if (model.has_children){ %>


	        <% _.each(_.range(model.total_components), function(element, index, list){ %>


	        	<% if (_.indexOf(Archives.data.series_and_subseries_ids, (parseInt(model.id) + index + 1)) === -1){ %>

	        	  <% counter.count++;  %>

					<%

						if ((counter.count === 0 || counter.count % Archives.a('componentsPerPass') === 0) && Archives.a('useGroupingRender')){

							if (counter.count !== 0){
								%> 
								</div>
								<%
							} 
							%>
							<div class="collection-detailed-block">
							<%
						}
					%>

		          <div id="c<%=(model.id + index + 1)%>" class="collection-detailed-row<%=  (element.level_text === 'series' || element.level_text === 'subseries' ) ? ' margin-' + element.level_text : ''%>">

		          	Loading...
		          </div>
		        
		        <% } %>



	        <% }); %>




	      <% } %>  



	    <% } %>


       """

window.Archives.templates['skeleton'] = window.Archives.templates['skeleton'].replace(/\n/g, '').replace(/\s{2,}/g,'');

