class SearchIndex < ActiveRecord::Base
  
  BATCH_SIZE = 100
  
  include SearchIndexMethods
  
  attr_accessible :index_type, :adds, :updates, :deletes, :processing_errors
    
  def execute
    self.index_type ||= 'full'
    @solr = RSolr.connect(:url => SOLR_WRITE_URL, :read_timeout => 500, :open_timeout => 500)
    @stats = { :add => 0, :update => 0, :delete => 0, :error => 0 }
    @i = 0
    
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
    
    puts response
  end
  
  
  def full_index
    # return nil if instace vars set in self.execute are undefined
    if !(defined?(@solr) && defined?(@stats) && defined?(@i))
      return nil
    else
      # full_clean = delete all records from index first
      if self.index_type == 'full_clean'
        self.index_clean
      end
    
      # Get active collections in batches of 10 and add to/update in index
      Collection.includes( :description, :access_term_associations, :org_unit ).
        where(:active => true).
        find_in_batches(:batch_size => 10) do |records|
          solr_update(records)
        end
      
      # Get components in active collections in batches of BATCH_SIZE and add to/update in index
      Component.includes( :description, :access_term_associations, :org_unit ).
        joins(:collection).where('collections.active' => true).
        find_in_batches(:batch_size => BATCH_SIZE) do |records|
          solr_update(records)
        end
      
      # Calculate num records deleted from index
      if (self.index_type == 'full_clean') && defined?(@total_pre_clean)
        if (@total_pre_clean > (@stats[:add] + @stats[:update]))
          @stats[:delete] = @total_pre_clean - (@stats[:add] + @stats[:update])
        end
      end
      
    end
  end


  def index_clean
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
  
  
  def add_collection_to_index(collection_id)
    @solr = RSolr.connect(:url => SOLR_WRITE_URL, :read_timeout => 500, :open_timeout => 500)
    collection = Collection.find collection_id
    solr_update_single(collection)
    Component.find_in_batches(:conditions => "collection_id = #{collection.id}") do |records|
      solr_update(records)
    end
    @solr.optimize
  end
  
  
  # One-stop shop to update a collection = delete + add
  def update_collection_in_index(collection_id)
    @stats = { :add => 0, :update => 0, :delete => 0, :error => 0 }
    @i = 0
    delete_collection_from_index(collection_id)
    add_collection_to_index(collection_id)
  end
  
  
  def delete_component_from_index(component_id)
    @solr = RSolr.connect(:url => SOLR_WRITE_URL, :read_timeout => 500, :open_timeout => 500)
    component = Component.find component_id
    @solr.delete_by_query "unique_id:#{component.unique_id}"
    @solr.commit
  end
  
end