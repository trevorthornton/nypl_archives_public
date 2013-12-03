class SearchesController < ApplicationController
  
  include SearchesHelper

  def results
    @page_title = "Search Results"
    @q = !params[:q].blank? ? params[:q] : nil
    params[:page] ||= 1
    params[:per_page] ||= 50
    params[:filters] ||= {}
    if params[:prefilter]
      case params[:prefilter]
      when 'org_unit_code'
        if params[:org_unit_code]
          org_unit_code = params[:org_unit_code].upcase
          @org_unit = OrgUnit.where(:code => org_unit_code).first
          if @org_unit
            @prefilter = params[:prefilter]
            params[:filters]['org_unit_code'] = org_unit_code
          else
            redirect_to '/'
          end
        end
      end
    end
    
    @filters = !params[:filters].blank? ? params[:filters] : nil
    @facets_set = (@filters && !@prefilter) ? true : false
    @display_facets = {
      'dates_decade' => 'Filter by date'
    }
    
    s = Search.new(params)
    @response = s.execute
    
    puts "RESPONSE #{@response["facet_counts"]["facet_fields"]}"
    @facet_counts = facet_counts
    
    puts "FACET COUNTS #{@facet_counts}"
    
    # @facet_values = @facet_counts.keys.sort
    puts "FACET VALUES #{@facet_values}"
    
    @facet_list = facet_list
    
    puts @response.request
    puts @filters
    
    @pagination_details = search_pagination_details(params)
    
  end


  def controlaccess
    @page_title = "Collections Matching '#{params[:term]}'"
    
    @index_term = params[:term]
    
    @hide_facets = true
    
    params[:page] ||= 1
    params[:per_page] ||= 25
    
    params[:simple] = true
    params[:q] = 'access_terms: "' + params[:term] + '" AND type: collection'
    
    puts "params! #{params.inspect}"
    
    s = Search.new(params)
    @response = s.execute
    puts @response.inspect
    
    @pagination_details = search_pagination_details(params)
    render :results
  end



  
  
end