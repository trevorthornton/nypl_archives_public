module SearchesHelper
    
  include ApplicationHelper
  
  def search_pagination_details(params)
    total = @response["response"]["numFound"]
    search_pagination_details = pagination_details(params,total)
    search_pagination_details[:href] = { :controller => 'searches', :action => 'results', :q => params[:q], :filters => params[:filters] }    
    search_pagination_details
  end
  
  
  def render_component_path(doc)
    separator = " / "
    path = ''
    path += "<div class='collection'>"
    path += doc['collection_title']
    path += "</div>"
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
  
  
  def facet_counts
    facet_counts_raw = @response["facet_counts"]["facet_fields"]
    i = 0
    counts = {}
    facet_counts_raw.each do |k,v|
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
  
  
  def facet_form_elements
    facets_output = ""
    if !@display_facets.blank?
      @display_facets.each do |k,v|        
        facets_output += "<div class='facet_name'>#{v}</div>"
        facets_output += facet_select(k)
      end
    end
    facets_output
  end
  
  
  def facet_select(field)
    facet_select_output = ""    
    base_link = @pagination_details[:href]
    facet_options = []
    facet_values = @facet_counts[field].keys.sort
    facet_values.each do |f|
      count = @facet_counts[field][f] 
      facet_options << ["#{facet_label(field,f,count)}", f]
    end
    
    if @filters && @filters[field.to_sym]
      select_options = options_for_select(facet_options, @filters[field.to_sym])
    else
      select_options = options_for_select(facet_options)
    end
    select_tag("filters[#{field}]",select_options,:include_blank => true)
  end
  
  
  def filter_reset
    reset_link = @pagination_details[:href].clone
    reset_link.delete(:filters)
    link_to "Reset filters", reset_link, {:class => "btn btn-small"}
  end


  def facet_label(field,facet,count=nil)
    if field == 'dates_decade'
      label_value = "#{facet}'s"
    else
      label_value = "#{facet}"
    end
    label_value += count ? " (#{count.to_s})" : ''
    return label_value
  end


  def facet_list
    facet_list = []
    if @filters
      @filters.each do |k,v|
        if k != @prefilter
          case v
          when String, Integer
            facet_list << facet_label(k,v,false)
          when Array
            v.each { |f| facet_list << facet_label(k,f,false) }
          end
        end
      end
    end
    facet_list
  end
  
end