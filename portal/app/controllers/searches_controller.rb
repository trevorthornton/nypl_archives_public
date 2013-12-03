class SearchesController < ApplicationController
  
  include SearchesHelper
  
  def index
    
  end
  
  
  def results
    
    set_search_filters(params)
    
    set_search_variables(params)
    
    @hide_facets = params[:hide_facets] ? true : nil
    
    # generate solr prams and perform query
    @solr_params = params.clone
    @solr_params[:page] = 1
    @solr_params[:per_page] = 3000
    s = Search.new(@solr_params)
    
    @response = s.execute
    
    puts "@response.request"
    puts @response.request
    
    set_response_variables(params)
    
    process_response()
    
    # facet variables used in view
    # remove :collection_id from @filters - this can only happen here, not before process_response()
    if @filters
      @filters.delete(:collection_id)
      @facets_set = (!@filters.empty? && !@prefilter) ? true : false
    else
      @facets_set = false
    end
    
    @display_facets = display_facets()
    
    # @pagination_details[:href] is used to generate links for both pagination and filters
    if @url_extension
      @base_href_options.merge!(@url_extension)
    end
    
    # define pagination details for view
    pagination_params = params.clone
    pagination_params[:per_page] = @collections_per_page
    @pagination_details = search_pagination_details(pagination_params, @total_collections)
    
    case params[:prefilter]
    when 'org_unit_code'
      @pagination_details[:href] = org_unit_results_path(@base_href_options)
      @display_facets.delete('access_name')
    when 'access_term_id'
      @pagination_details[:href] = controlaccess_results_path(@base_href_options)
    end
        
    # Set link back to search results (to display on collection/show)
    session[:return_to] = request.fullpath

    # @facet_list = facet_list
    @facet_values = @facet_counts.keys.sort   
    
    # TEST
    puts "COUNT VARS"
    puts @facet_counts['collection_id'].inspect
    puts @total_collections
  end



  def collection
    if !params[:collection_id]
      flash[:warning] = messages[:not_found]
      redirect_to request.referrer
    else
      @collection = Collection.find params[:collection_id]
      if params[:q].blank?
        redirect_to persistent_collection_path(@collection.attributes.symbolize_keys)
      else
        @q = params[:q]
        @base_href_options = { :q => params[:q], :filters => @filters }
        
        params[:page] ||= 1
        params[:per_page] ||= 25
        @page = params[:page].to_i
        
        
        params[:filters] ||= {}
        params[:filters][:collection_id] = params[:collection_id]
        params[:filters][:type] = 'component'
        
        set_search_filters(params)
        
        # set_search_variables(params)
            
        s = Search.new(params)
        @response = s.execute
        @results = @response["response"]["docs"]
        
        @facet_counts = facet_counts()
        
        if @filters
          @filters.delete(:collection_id)
          @filters.delete(:type)
          @facets_set = (!@filters.empty? && !@prefilter) ? true : false
        else
          @facets_set = false
        end
        
        @display_facets = display_facets()
    
        @pagination_details = search_pagination_details(params)
        @pagination_details[:href] = collection_results_path(@base_href_options)
        
        # Set link back to search results (to display on collection/show)
        session[:return_to] = request.fullpath
    
        render :results
        
      end
    end
  end
  
  
  private
  
  def set_search_variables(params)
    @collections_per_page = 30
    @base_href_options = { :q => params[:q], :filters => @filters }
    
    @q = !params[:q].blank? ? params[:q] : nil
    params[:page] ||= '1'
    @page = params[:page].to_i
    
    @start_seq = params[:start_seq] ? params[:start_seq].split('+') : [0]
    @start = @start_seq[@page - 1].to_i
    
    params[:start] = @start
    
    @id_subset_start = @collections_per_page * (@page - 1)
    
    # @exclude_id_subset_start = @collections_per_page * (@page - 1)
    
    if params[:result_set_collection_ids]
      @result_set_collection_ids = params[:result_set_collection_ids].split('+')
    else
      @result_set_collection_ids = []
    end

    @result_set_collection_ids.map! { |x| x.to_i }
         
    # 2 methods of filtering: exclusion (for new pages) or inclusion (for previously-viewed pages)
    if (@result_set_collection_ids.length / @collections_per_page) > @page
      @current_included_ids = @result_set_collection_ids.slice(@id_subset_start, @collections_per_page)
    else
      @current_included_ids = nil
    end
    
    @first_collection_index = (@page - 1) * @collections_per_page
    
    # All of these variables must be passed in params for pages > 1
    # if page == 1, these are set after Solr response is received
    if @page > 1 || @current_included_ids
      @total_pages = params[:total_pages].to_i
      @total_collections = params[:total_collections].to_i
      if @id_subset_start < @result_set_collection_ids.length
        @current_excluded_ids = @result_set_collection_ids.clone
        @current_excluded_ids.slice!(@id_subset_start, @current_excluded_ids.length - 1)
      else
        @current_excluded_ids = @result_set_collection_ids.clone
      end
    else
      @current_excluded_ids = []
    end    
    
  end
  
  
  def set_search_filters(params)
    if params[:reset_filters]
      params[:filters] = {}
    else
      params[:filters] ||= {}
    end
    
    params[:filters].delete_if { |k,v| v.blank? }
    
    @filters = !params[:filters].blank? ? params[:filters].clone : {}
    
    # special treatment for date range filter
    if @filters['date_range']
      years = @filters['date_range'].split('/')
      params[:filters]['dates_index'] = "[#{years.first} TO #{years.last}]"
      params[:filters].delete('date_range')
    end
    
    if params[:prefilter]
      @prefilter = params[:prefilter]
      @url_extension = { :prefilter => @prefilter }
      case params[:prefilter]
      when 'org_unit_code'
        if params[:org_unit_code]
          @url_extension[:org_unit_code] = params[:org_unit_code]
          org_unit_code = params[:org_unit_code].upcase
          @org_unit = OrgUnit.where(:code => org_unit_code).first
          if @org_unit
            params[:filters]['org_unit_code'] = org_unit_code
            params[:filters]['type'] = 'collection'
            params[:sort] = 'origination_ss asc'
          end
        end
      when 'access_term_id'
        if params[:access_term_id]
          @term = params[:term]
          @url_extension[:access_term_id] = params[:access_term_id]
          @url_extension[:term] = @term 
          if @term
            params[:filters][:access_term_id] = params[:access_term_id]
            @base_href = "/controlaccess/#{params['access_term_id']}?term=#{params['term']}"
          end
        end
      end
    end
    
  end
  
  
  def set_response_variables(params)
    # Some facet variables
    @facet_counts = facet_counts 
    
    @components_per = 5
    @docs = @response["response"]["docs"]
    @collections = {}
    @results = []
    @collection_ids = []
    
    if @page == 1
      @total_collections ||= @facet_counts['collection_id'].length
      @total_pages ||= (@total_collections.to_f / @collections_per_page.to_f).ceil
    end
    
    if @total_collections < @collections_per_page
      @collection_max = @total_collections
    # elsif @first_collection_index > 0
    #   @collection_max = @first_collection_index + @collections_per_page
    else
      @collection_max = @collections_per_page
    end
    
  end
  
  
  def process_response
    
    collection_full = lambda do |collection|
      max = (collection['total_component_results'] < @components_per) ? collection['total_component_results'] : @components_per
      if max > 0
        if collection['components']
          return collection['components'].length == max ? true : false
        else
          return false
        end
      else
        
        puts "Collection #{collection[:id]} full"
        
        return true
      end
    end
    
    add_collection_from_component = Proc.new do |component|
      new_collection = {
        'id' => component['collection_id'],
        'title' => component['collection_title'],
        'origination' => [component['collection_origination']],
        'date_statement' => component['collection_date_statement'],
        'extent_statement' => component['collection_extent_statement'],
        'abstract' => [component['collection_abstract']],
        'org_unit_name' => component['org_unit_name'],
        'call_number' => component['collection_call_number'],
        'type' => 'collection'
      }
            
      new_collection['total_component_results'] = @facet_counts['collection_id'][component['collection_id'].to_s]
      
      @collections[component['collection_id']] = new_collection
      
    end
    
    all_collections_full = lambda do
      all_full = true
      if @collections.length < @collection_max
        all_full = false
      elsif @collections.length == @collection_max 
        @collections.each do |id,c|
          
          if !(collection_full.call(c))
            all_full = false
            break
          end
        end
      end
      return all_full
    end
    
    
    @next_start = nil
    i = @start - 1
        
    @docs.each do |d|
      i += 1
      if !@current_excluded_ids.include?(d['collection_id'])
        
        if d['type'] == 'collection'
          if @collections.length == @collection_max
            @next_start ||= i
            next
          else
            d['total_component_results'] = (@facet_counts['collection_id'][d['id'].to_s] - 1) || 0
            
            @collections[d['id']] ||= d     
            
            if !@collection_ids.include? d['id']
              @collection_ids << d['id'] 
            end
            if !@result_set_collection_ids.include? d['id']
              @result_set_collection_ids << d['id'] 
            end
            
          end
        else # component result
          collection_id = d['collection_id']

          if !@collections[collection_id]  
            if @collections.length < @collection_max 
              add_collection_from_component.call(d)
              
              if !@collection_ids.include?(collection_id)
                @collection_ids << collection_id 
              end
              
              if !@result_set_collection_ids.include?(collection_id)
                @result_set_collection_ids << collection_id 
              end
              
            elsif all_collections_full.call
              # all collection on this page are full - stop here
              @next_start ||= i
              break
            else
              # this is a component from a collection that will be on the next page
              @next_start ||= i
              next
            end
          end
                
          collection = @collections[collection_id]
          
          if !(collection_full.call(collection))
            
            (collection['components'] ||= []) << d
            
          end
        end
        
      else
        
      end
    end
    
    # prepare results
    
    display_collection_ids = @result_set_collection_ids.slice(@first_collection_index, @collections_per_page)
    
    # puts '@result_set_collection_ids'
    # puts @result_set_collection_ids.inspect
    # puts '@result_set_collection_ids length'
    # puts @result_set_collection_ids.length
    # puts '@first_collection_index'
    # puts @first_collection_index.inspect
    # puts 'display_collection_ids'
    # puts display_collection_ids.inspect
    
    
    # generate results based on order of display_collection_ids array to maintain relevancy order
    display_collection_ids.each do |id|

      # puts "Adding collection #{id} to @results"
      # puts @collections[id].class.to_s

      @results << @collections[id]

      if !@result_set_collection_ids.include? id
        @result_set_collection_ids << id
      end
    end
        
    # set @result_set_collection_ids back to string
    @result_set_collection_ids.map! { |x| x.to_s }
    @result_set_collection_ids = @result_set_collection_ids.uniq.join '+'
    
    # add @next_start to @start_seq, then convert to string
    @start_seq << @next_start
    @start_seq = @start_seq.join '+'
    
    puts @start_seq
    
  end
  

  
end