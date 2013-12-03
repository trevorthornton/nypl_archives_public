class AuthoritydataSearch
  
  # Allowed keys for options are rows (int), start (int), filters (array)
  def search(q, options={}, element_type=nil)
    
    solr = RSolr.connect :url => AUTHORITY_QUERY_URL
    
    solr_params = {:q => q}
    
    # Specify query parameters based on type of search being performed
    case element_type
    when 'name'
      solr_params[:bq] = "authority_code:naf^10.0"
      if options[:filters]['term_type'].nil?
        options[:filters]['term_type'] = ['name_personal', 'name_corporate', 'name_conference', 'name_meeting']
      end
    when 'topic'
      solr_params[:bq] = "authority_code:lcsh^20.0 aat^10.0"
    when 'genre','form'
      solr_params[:bq] = "authority_code:lcgft^20.0 aat^10.0"
    when 'geographic','hierarchicalGeographic'
      solr_params[:bq] = "authority_code:naf^20.0 tgn^15.0"
      if options[:filters]['term_type'].nil?
        options[:filters]['term_type'] = ['geographic', 'subdivision_geographic']
      end
    end
    
    if !options[:filters].blank?
      fq = []
      options[:filters].each do |key,facet_array|
        if !facet_array.blank?
          fq1 = "#{key}:("
          
          facet_array.each_index do |index|
            facet_value = facet_array[index].to_s.gsub(" ", "+")
            fq1 += (index > 0) ? " " : ""
            fq1 += facet_value
          end
          
          fq1 += ")"
          fq << fq1
        end
      end
      solr_params[:fq] = fq
    end
    
    solr_params[:defType] = 'dismax'
    solr_params[:qf] = 'term_idx alternate_term_idx'
    solr_params[:mm] = 0
    solr_params[:wt] = :ruby
    solr_params[:facet] = true
    solr_params['facet.mincount'] = 1
    # Specify facet fields - facet UI elements will display in order listed here
    
    facet_fields = ['term_type','authority_name']
    solr_params['facet.field'] = facet_fields
    
    puts "solr_params: #{solr_params}"
    
    response = solr.paginate options[:page], options[:per_page], 'select', :params => solr_params
  end
  
end