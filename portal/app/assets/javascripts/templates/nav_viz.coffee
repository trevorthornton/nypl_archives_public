window.Archives.templates['nav_viz'] = """
       
 		

		<div id="nav-viz" style="height: <%=dom_height%>px">



			<% _.each(canvas_pages, function(e,i){ %>

				<canvas width="<%=canvas_width%>px" id="nav-viz-<%=i%>" height=<%=e.height%>px>


				</canvas>


			<% }) %>


			<div class="highlight"></div>

		</div>



       """

window.Archives.templates['nav_viz'] = window.Archives.templates['nav_viz'].replace(/\n/g, '').replace(/\s{2,}/g,'');

