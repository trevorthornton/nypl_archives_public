window.Archives.templates['navSide'] = """
       
 
		  <% _.each(model.components, function(series) { %>

		  		

		      <% if (Archives.a('isFiltered')){ %>



		      	<li class="nav-series-li">

		      	  <% if (Archives.filter.parentCount[series.id]){ %>

		      	  	<a href="#c<%=series.id%>">
			      
			      <% }else{ %>

			      	<div class="no-hit-menu-item">

			      <% } %>		

			      

			      <% if (typeof series.components != 'undefined'){ %>
			        <span class="caret"></span>
			      <% }else{ %>
			        <span class="caret caret-hidden"></span>
			      <% } %>

			      <%=series.title%>


		      	  <% if (Archives.filter.parentCount[series.id]){ %>

		      	  	<span class="hit-indicator"><%=Archives.filter.parentCount[series.id]%> Hit<%=(Archives.filter.parentCount[series.id] > 1) ? 's' : ''%> </span>  

		      	  	</a>
			      
			      <% }else{ %>

			      	</div>

			      <% } %>	
			      

			      <% if (typeof series.components != 'undefined'){ %>
			        <div class="nav-subseries-container" id="nav-subseries-container-<%=series.id%>">
			        <ul class="nav nav-tabs nav-stacked ">

			        <% _.each(series.components, function(subseries) { %>

			                  <li class="nav-subseries-li">

					      	  <% if (Archives.filter.parentCount[subseries.id]){ %>

					      	  	<a href="#c<%=subseries.id%>">
						      
						      <% }else{ %>

						      	<div class="no-hit-menu-item">

						      <% } %>	


			                  
			                  <%=subseries.title%>
			               

					      	  <% if (Archives.filter.parentCount[subseries.id]){ %>

					      	 	<span class="hit-indicator"><%=Archives.filter.parentCount[subseries.id]%> Hit<%=(Archives.filter.parentCount[subseries.id] > 1) ? 's' : ''%></span>

					      	  	</a>
						      
						      <% }else{ %>

						      	</div>

						      <% } %>	


			                  </li>

			        <% }); %>
			        </ul>
			        </div>
			      <% } %>


			    </li>


			  <% }else{ %>
			  

		      	<li class="nav-series-li">

			      <a href="#c<%=series.id%>">

			      <% if (typeof series.components != 'undefined'){ %>
			        <span class="caret"></span>
			      <% }else{ %>
			        <span class="caret caret-hidden"></span>
			      <% } %>

			      <%=series.title%>

			      </a>
			      
			      <% if (typeof series.components != 'undefined'){ %>
			        <div class="nav-subseries-container" id="nav-subseries-container-<%=series.id%>">
			        <ul class="nav nav-tabs nav-stacked ">

			        <% _.each(series.components, function(subseries) { %>
			                  <li class="nav-subseries-li">
			                  <a href="#c<%=subseries.id%>">
			                    <%=subseries.title%>
			                  </a>
			                  </li>

			        <% }); %>
			        </ul>
			        </div>
			      <% } %>


			    </li>


			  <% } %>   


		  <% }); %> 

       """

window.Archives.templates['navSide'] = window.Archives.templates['navSide'].replace(/\n/g, '').replace(/\s{2,}/g,'');

