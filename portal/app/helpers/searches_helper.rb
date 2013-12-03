module SearchesHelper
    
  include ApplicationHelper
  
  def search_pagination_details(params,total=nil)
    total ||= @response["response"]["numFound"]
    search_pagination_details = pagination_details(params,total)
    search_pagination_details[:href] = { :controller => params[:controller], :action => params[:action], :q => params[:q], :filters => @filters }    
    search_pagination_details
  end
  
  
  def component_path(doc)
    separator = " / "
    path = ''
    # path += "<div class='collection'>"
    # path += doc['collection_title']
    # path += "</div>"
    if doc['component_path']
      doc['component_path'].each do |p|
        path += "<span class='path_part'>"
        path += p
        path += separator
        path += "</span>\n"
      end
    end
    path
  end
  
  
  def location_string(doc)
    string = doc['org_unit_name']
    if doc['call_number']
      string += " | #{doc['call_number']}"
    end
    string
  end
  
  
  def facet_counts
    facet_counts_raw = @response["facet_counts"]["facet_fields"]
    counts = {}
    facet_counts_raw.each do |k,v|
      i = 0
      counts[k] = {}
      until i > (v.length - 1) do
        # fix this in Solr, this '0' problem
        if v[i] != '0'
          counts[k][v[i]] = v[i + 1]
        end
        i += 2
      end
    end
    counts
  end
  
  
  # def facet_form_elements
  #   facets_output = ""
  #   if !@display_facets.blank?
  #     @display_facets.each do |k,v|        
  #       facets_output += "<div class='facet_name'>#{v}</div>"
  #       facets_output += facet_select(k)
  #     end
  #   end
  #   facets_output
  # end

  
  def facets
    output = ""
    if !@display_facets.blank?
      @display_facets.each do |k,v|  
        output += facet_select(k)
      end
      if !output.blank?
        output += filter_reset
      end
    end
    output
  end
  
  
  def filter_link_params
    
    
    
    link_params = {}
    link_params[:base_href] = @base_href_options.clone
    link_params[:active_filters] = link_params[:base_href].delete(:filters) || []
    link_params
  end
  
  
  def filter_deselect_link(field)
    link_params = filter_link_params
    href = link_params[:base_href].clone
    if !link_params[:active_filters].blank?
      href[:filters] = {}
      link_params[:active_filters].each do |k,v|
        if k != field
          href[:filters][k] = v
        end
      end
    end
    link_to 'x', href, :class => 'facet-deselect removelink'
  end
  
  
  def facet_select(field)
    
    facet_label = @display_facets[field]
    
    facet_content = ""    
    link_params = filter_link_params
    
    
    
    facet_values = []
    
    if @filters && @filters[field]

        
      puts 'facet_select - @filters'
      puts @filters.inspect
      
      # deselect mode - only display active filter with link to remove it    
      href = link_params[:base_href].clone
      if !link_params[:active_filters].blank?
        href[:filters] = {}
        link_params[:active_filters].each do |k,v|
          if k != field
            href[:filters][k] = v
          end
        end
      end
      
      label_value = facet_label(field,@filters[field])

      facet_content += "<div class='active-facet'>"
      facet_content += filter_deselect_link(field)
      facet_content += label_value
      facet_content += "</div>"
      
    else    
      # select mode - display all active options with links
      
      if field == 'dates_decade'
        facet_values = @facet_counts[field].keys.sort
      elsif field == 'date_range'
        ranges = date_ranges
        years = @facet_counts['dates_index'].keys.sort
        ranges.each do |k,v|
          y = years.select { |x| (x.to_i >= v[:start]) && (x.to_i <= v[:end]) }
          if !y.empty?
            (facet_values ||= []) << "#{v[:start].to_s}/#{v[:end].to_s}"
          end
        end
        
      else
        facet_values_raw = @facet_counts[field].sort_by { |k,v| v }
        facet_values_raw.reverse!
        facet_values_raw.each { |a| facet_values << a[0] }
      end
      
      if field == 'access_name'
        facet_values.slice!(40,facet_values.length)
      end
      
      
      if facet_values.length > 1
        if facet_values.length > 5
          facet_content += "<div class='facet-value-select'>"
        else
          facet_content += "<div class='facet-value-select noscroll'>"
        end
        
        facet_content += "<ul>"
      
        facet_values.each do |f|
          href = link_params[:base_href].clone
          
          href[:filters] = { field => f }
          link_params[:active_filters].each { |k,v| href[:filters][k] = v }
          
          label_value = facet_label(field,f)
          
          facet_content += "<li>"
          facet_content += link_to label_value, href, :class => 'facet-select'
          facet_content += "</li>"

        end
        facet_content += "</ul>"
        facet_content += "</div>"
      end
    end
    
    if !facet_content.blank?
      output = "<div class='facet'>"      
      output += "<div class='facet-name'>#{facet_label}</div>"
      output += facet_content
      output += "</div>"
    else
      output = ''
    end
    
    output
  end
  
  
  def filter_reset
    reset_link = @base_href_options.clone
    reset_link.delete(:filters)
    output = "<div class='filter-reset'>"
    output += link_to "Reset filters", reset_link, {:class => "btn btn-small"}
    output += '</div>'
  end


  def facet_label(field,facet,count=nil)
    case field
    when 'dates_decade'
      label_value = "#{facet}s"
    when 'date_range'
      label_value = facet.gsub(/\//, ' - ')
    else
      label_value = "#{facet}"
    end

    label_value += count ? " (#{count.to_s})" : ''
    return label_value
  end


  def facet_list
    list = []
    output = ''
    list_item = lambda do |field,value|
      item = filter_deselect_link(field)
      item += facet_label(field,value,false)
      return item
    end
    
    if @filters
      @filters.each do |k,v|
        if k != @prefilter
          case v
          when String, Integer
            list << list_item.call(k,v)
          when Array
            v.each { |f| list << list_item.call(k,f) }
          end
        end
      end
    end
    
    if !list.empty?
      output += "<div class='active-filters'>Filtering on: "
      list.each { |i| output += "#{i} " }
    	output += '</div>'
    end
    output
  end
  
  
  def search_results_heading
    if @page_title
	    @page_title
	  elsif params[:action] == 'collection'
	    "<span class='subtitle'>Matches for <span class='search-term'>#{@q}</span> in</span>
	      <span class='search-scope'>#{link_to @collection.title, persistent_collection_path(:id => @collection.id)}</span>"
	  elsif @prefilter == 'org_unit_code' && @org_unit
	    "Collections in #{@org_unit.name}"
  	elsif @prefilter == 'access_term_id' && @term
    	"<span class='subtitle'>Found #{pluralize @total_collections, 'collection'} related to</span>
    	  <strong>#{@term}</strong>"
  	elsif @q && @total_collections
    	"Found matches for <strong>#{params[:q]}</strong> in #{@total_collections.to_s} collections."
  	else
  		"Found #{pluralize @total_collections.to_i, 'collection'}."
  	end 
  end
  
  
  def component_results(doc)
    output = ''
    if doc['components'] && !doc['components'].empty?
      output += "<div class='component-results'>\n"
      output += "<h3>Found in</h3>"
      doc['components'].each do |c|
        output += "<div class='component-result'>\n"
        link_text = ''
        if c['component_path']
          link_text += "<span>#{c['component_path'].join(' &raquo; ')}</span>"
          link_text += ' &raquo; '
        end
        link_text += "<span class='component_title'>#{c['title']}</span>"
        
        # generate link to component
        component_link = persistent_component_path(c)
        
        output += link_to(link_text.html_safe, component_link, { :class => 'component-link' })
        output += "</div>\n"
      end
      if doc['total_component_results'] > @components_per
        output += "<div class='collection-search-link'>"
        # url = "/search/collection/#{doc['id']}?q=#{@q}"
        url_params = { :q => @q, :collection_id => doc['id'], :filters => @filters }
        
        output += link_to "See all #{doc['total_component_results']} matches in this collection", collection_results_path(url_params)
        output += "</div>\n"
      end
      output += "</div>\n"
    end
    output
  end
  
  
  def display_facets
    { 'date_range' => 'Filter by date range',
      'org_unit_name' => 'Filter by division/collection',
      'access_name' => 'Filter by name' }
  end
  
  
  def date_ranges
    this_year = DateTime.now.strftime('%Y').to_i
    ranges = {}
    i = 1001
    until i > 2100
      range_start = i
      range_end = i + 49
      key = range_start
      ranges[key] = { :start => range_start, :end => range_end > this_year ? this_year : range_end }
      i = range_end + 1
    end
    ranges
  end
  
  
  def range_lookup(year,ranges)
    # 1934
    ranges.keys.select { |x| x <= year }.last
    
  end
  
  
  def append_page_to_url(path,page)
    url = url_for(path)
    url += url.match(/\?/) ? "&page=#{page.to_s}" : "?page=#{page.to_s}"
    url
  end


  def has_digital_assets(docs)
    we_be_digital = false
    docs.each do |d|
      if d['digital_assets']
        we_be_digital = true
      end
    end
    we_be_digital
  end


  
end