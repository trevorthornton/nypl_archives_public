class SearchIndex < ActiveRecord::Base
  
  BATCH_SIZE = 20
  
  include SearchIndexMethods
  
  attr_accessible :index_type, :adds, :updates, :deletes, :processing_errors, :index_scope
  
  attr_accessor :start
  
  def execute
    self.index_type ||= 'full'
    @solr = RSolr.connect(:url => SOLR_WRITE_URL, :read_timeout => 500, :open_timeout => 500)
    @stats = { :add => 0, :update => 0, :delete => 0, :error => 0 }
    @i = 0
    
    if self.index_scope && !['Collection','Component'].include?(self.index_scope)
      puts "Hold up! The value you supplied for index_scope is not valid - needs to be either 'Collection' or 'Component'."
      return false
    else
      case self.index_type
      # full = add/update all active records
      when 'full', 'full_clean'  
        self.full_index
      # delta = add/update records added/updated to db since last index
      when 'delta'
        self.delta_index 
      end
    
      response = "#{@stats[:update].to_s} documents updated. #{@stats[:add].to_s} documents added. #{@stats[:delete].to_s} documents deleted. #{@stats[:error].to_s} errors."
    
      self.attributes = { :adds => @stats[:add], :updates => @stats[:update], :deletes => @stats[:delete], :processing_errors => @stats[:error] }
      self.save
    
      logger.info response; puts response
    end
  end


  def full_index
    # return nil if instace vars set in self.execute are undefined
    if !(defined?(@solr) && defined?(@stats) && defined?(@i))
      return nil
    else
      # full_clean = delete all records from index first
      if self.index_type == 'full_clean'
        self.wipe_index
      end
      
      if self.index_scope != 'Component'
        # Get active collections in batches of 10 and add to/update in index
        Collection.includes( :description, :access_term_associations, :org_unit ).
          where(:active => true).
          find_in_batches(:batch_size => BATCH_SIZE, :start => self.start ? self.start : 0) do |records|
            solr_update(records)
          end
      end
      
      if self.index_scope != 'Collection'
        # Get components in active collections in batches of BATCH_SIZE and add to/update in index
        Component.includes( :description, :access_term_associations, :org_unit ).
          joins(:collection).where('collections.active' => true).
          find_in_batches(:batch_size => BATCH_SIZE) do |records|
            solr_update(records)
          end
      end
      
      # Calculate num records deleted from index
      if (self.index_type == 'full_clean') && defined?(@total_pre_clean)
        if (@total_pre_clean > (@stats[:add] + @stats[:update]))
          @stats[:delete] = @total_pre_clean - (@stats[:add] + @stats[:update])
        end
      end
      
    end
  end


  def wipe_index
    # return nil if instace vars set in self.execute are undefined
    if !(defined?(@solr) && defined?(@stats))
      return nil
    else
      pre_clean_rsp = @solr.get 'select', :params => { :q => '*:*', :rows => 0 }
      @total_pre_clean = pre_clean_rsp['response']['numFound'].to_i
      @solr.delete_by_query '*:*'
      @solr.commit
    end
  end
  
  
  def prune_index
    rows_per = 1000
    @solr = RSolr.connect(:url => SOLR_WRITE_URL, :read_timeout => 500, :open_timeout => 500)
    pre_response = @solr.get 'select', :params => { :q => '*:*', :rows => 0 }
    total_records_in_index = pre_response['response']['numFound'].to_i
    i = 1
    while i < total_records_in_index
      delete_ids = []
      start = i
      response = @solr.get 'select', :params => { :q => '*:*', :rows => rows_per, :start => start }
      response["response"]["docs"].each do |d|
        case d[:type]
        when 'collection'
          c = Collection.where(:id => d[:id]).first
          if !c
            delete_ids << "collection_#{d[:id].to_s}"
          end
        when 'component'
          c = Component.where(:id => d[:id]).first
          if !c
            delete_ids << "component_#{d[:id].to_s}"
          end
        end
      end
      
      puts delete_ids.inspect
      
      # @solr.delete_by_query '*:*'
      # @solr.commit
      
      i += rows_per
    end    
  end
  
  
  def delta_index
    # return nil if instace vars set in self.execute are undefined
    if !(defined?(@solr) && defined?(@stats))
      return nil
    else
      previous_index = SearchIndex.order(:updated_at).last
    
      # Get active collections and components in batches of 1000 and add to/update in index
      Collection.includes( :description, :access_term_associations, :org_unit ).
        where('updated_at > ?', previous_index.updated_at).where(:active => true).
        find_in_batches(:batch_size => 1) do |records|
          solr_update(records)
        end
      
      # Get components in active collections in batches of BATCH_SIZE and add to/update in index
      Component.includes( :description, :access_term_associations, :org_unit ).
        joins(:collection).where('components.updated_at > ?', previous_index.updated_at).
        where('collections.active' => true).
        find_in_batches(:batch_size => BATCH_SIZE) do |records|
          solr_update(records)
        end
    end
  end  
  
  
  def delete_collection_from_index(collection_id)
    @solr = RSolr.connect(:url => SOLR_WRITE_URL, :read_timeout => 500, :open_timeout => 500)
    puts @solr.inspect
    collection = Collection.find collection_id
    puts collection.inspect
    
    response = @solr.delete_by_query "unique_id:#{collection.unique_id}"
    puts response
    sleep(2)
    
    # delete components from index
    response = @solr.delete_by_query "collection_id: #{collection_id} AND type:component"
    puts response
    sleep(2)

    @solr.optimize
  end
  
  
  def update_component_in_index(component_id)
    @solr = RSolr.connect(:url => SOLR_WRITE_URL, :read_timeout => 500, :open_timeout => 500)
    component = Component.find component_id
    solr_update_single(component)
    @solr.optimize
  end
  
  
  def add_collection_to_index(collection_id,options={})
    @solr = RSolr.connect(:url => SOLR_WRITE_URL, :read_timeout => 500, :open_timeout => 500)
    collection = Collection.find collection_id
    solr_update_single(collection)
    if options[:index_scope] != 'Collection'
      Component.find_in_batches(:conditions => "collection_id = #{collection.id}") do |records|
        solr_update(records)
      end
    end
    @solr.optimize
  end
  
  
  # One-stop shop to update a collection = delete + add
  def update_collection_in_index(collection_id,options={})
    @stats = { :add => 0, :update => 0, :delete => 0, :error => 0 }
    @i = 0
    if options[:index_scope] != 'Collection'
      delete_collection_from_index(collection_id)
    end
    add_collection_to_index(collection_id, options)
  end
  
  
  def delete_component_from_index(component_id)
    @solr = RSolr.connect(:url => SOLR_WRITE_URL, :read_timeout => 500, :open_timeout => 500)
    # component = Component.find component_id
    @solr.delete_by_query "unique_id:component_#{component_id}"
    @solr.commit
  end
  
end