class Search
  
  include SearchUtilityMethods
    
  def initialize(options = {})
    @q = options[:q]
    @filters = !options[:filters].blank? ? options[:filters] : nil
    @page = options[:page] || 1
    @per_page = options[:per_page] || 20
    @simple = options[:simple] || nil
    @target = options[:target] || nil
    @wt = options[:wt] || :ruby
    @start = options[:start] || 0
    @sort = options[:sort]
    if @sort
      @sort += @sort == 'created_at' ? ' desc' : ' asc'
    end
  end
  
  attr_accessor :q, :page, :per_page, :filters, :wt, :simple
  
  def execute
    
    @solr = RSolr.connect :url => SOLR_URL
    @solr_params = { :wt => self.wt || :ruby }
    
    @solr_params[:start] = @start
    
    @solr_params[:sort] = @sort if @sort
    
    if !self.simple
      @solr_params[:defType] = 'dismax'
      if !self.q.blank?
        @clean_q = SolrSanitizer.new.sanitize(self.q)
        # @solr_params[:q] = @clean_q
        @solr_params[:q] = self.q
      end
      @solr_params['q.alt'] = '*:*'
      
      puts "QUERY:"
      puts @solr_params[:q]
      
      # highlighting
      @solr_params['hl'] = true
      @solr_params['hl.fl'] = 'title origination scopecontent access_terms'
      @solr_params['hl.simple.pre'] = "<mark>"
      @solr_params['hl.simple.post'] = "</mark>"
    
      # facets
      @solr_params['facet'] = true
      @solr_params['facet.field'] = ["dates_decade", "dates_index", "collection_title", "collection_id", "type", "org_unit_name", "access_name"]
      @solr_params['facet.limit'] = -1
      @solr_params['facet.mincount'] = 1
      
      if @target
        case @target
        when 'controlaccess'
          query_fields = {
           'access_term_id' => nil
          }
        end
      else
        query_fields = {
         'boost_query' => 100000,
         'title' => 800,
         'origination' => 500,
         'title_t' => 1000,
         'origination_t' => 400,
         'call_number' => 300,
         'collection_title_t' => 1000,
         'mss_id' => nil,
         'access_terms' => nil,
         'access_terms_t' => nil,
         'scopecontent' => nil,
         'bioghist' => nil,
         'custodhist' => nil,
         'org_unit_name' => nil,
         'org_unit_name_t' => nil,
         'abstract' => nil,
         'pdf_content' => nil
        }
      end
      
      @solr_params[:bq] = 'type:collection^50'
      
      # @solr_params[:bf] = 'linear_feet^0.5'
      
      @solr_params[:qf] = ''
      
      query_fields.each do |k,v|
        @solr_params[:qf] += " #{k}"
        @solr_params[:qf] += v ? "^#{v}" : ''
      end
      @solr_params[:qf].strip!
      
      # phrase handling
      @solr_params[:mm] = '50%'
      
      @solr_params[:pf] = query_fields.keys
      @solr_params[:ps] = 3
      
    else
      @solr_params[:defType] = 'lucene'
      @solr_params[:q] = self.q
    end
    
    @solr_params['fq'] = "type: collection"
    
    if !@filters.blank?
      @filters.each do |k,v|
        if k == 'collection_id' || v =~ /^\[.*\]$/
          fq << "#{k}: #{v}" if !v.blank?
        else
          case v
          when String
            fq << "#{k}: \"#{v}\"" if !v.blank?
          when Array
            if !v.empty?
              v.each { |f| fq << "#{k}: #{f}" }
            end
          end
        end
      end
      @solr_params['fq'] = fq
    end
    
    @response = @solr.paginate self.page, self.per_page, "select", :params => @solr_params
    
  end
  
end