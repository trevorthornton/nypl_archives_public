class AuthoritydataSearchesController < ApplicationController
  
  include AuthoritydataSearchesHelper
  
  def show
    @element_type = params[:element_type]
    case @element_type
      when 'topic','temporal','occupation'
        @title = "Search topics and concepts"
      when 'name'
        @title = "Search names"
        @name_type_select_options = name_type_select_options()
      when 'geographic','hierarchicalGeographic'
        @title = "Search geographic names/terms"
      when 'genre', 'form'
        @title = "Search genre and form terms"
    end
    render :layout => false
  end

  def results
    # Get search query and filters
    @q = params[:q].length > 0 ? params[:q] : "[* TO *]"
    @element_type = params[:element_type]
    @selected_filters = params['selected_filters'] ? params['selected_filters'] : {}
    @filters = @selected_filters.clone
    @filters.each do |key,value|
      new_val = [value] if value.length > 0
      @filters[key] = new_val
    end
    
    @per_page = !params[:per_page].blank? ? params[:per_page].to_i : 10
    @page = !params[:page].blank? ? params[:page].to_i : 1
       
    @search_options = {:page => @page, :per_page => @per_page, :filters=> @filters}
        
    if @search_options[:filters]['authority_code'].nil?
      @search_options[:filters]['authority_code'] = relevant_authorities(@element_type)
    end
    
    puts "q = #{@q}"
    puts "search options = #{@search_options.inspect}"
    
    # Execute SOLR query
    @search = AuthoritydataSearch.new
    @response = @search.search(@q,@search_options,@element_type)
    
    puts "@response = #{@response.inspect}"
    
    @results = @response['response']['docs']
    @results_total = @response['response']['numFound']
    
    pager_options_for_views()
		
		render :layout => false
  end
  
end