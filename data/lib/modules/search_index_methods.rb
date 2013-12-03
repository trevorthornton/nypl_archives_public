module SearchIndexMethods
  
  include GeneralUtilityMethods
  
  # update Solr with a batch of records
  def solr_update(records)
    
    puts "Updating #{records.length.to_s} records..."
    
    docs = []
    batch_stats = { :add => 0, :update => 0 }
    
    # determine how many records in this batch are updates vs. adds
    update_check_ids = []
    records.each do |r|
      update_check_ids << r.unique_id
    end
    update_check_q = "unique_id:" + update_check_ids.join(' ')
    solr_r = @solr.get 'select', :params => { :q => update_check_q }
    updates = solr_r['response']['numFound']
    batch_stats[:update] += updates
    batch_stats[:add] += records.length - updates 
    
    records.each { |r|  docs << r.solr_doc_hash }
    if @solr.add docs
      @stats[:add] += batch_stats[:add]
      @stats[:update] += batch_stats[:update]
    else
      @stats[:error] += records.length
    end
    if @solr.commit
      @i += records.length
      puts "Total commits to Solr index: #{@i}"
    else
      puts "COMMIT FAILED!"
    end
  end
  
  
  
  def solr_update_single(record)
    doc = record.solr_doc_hash    
    if @solr.add doc
      if @solr.commit
        puts "Record updated and commited :)"
      else
        puts "Solr commit failed :("
      end
    else
      puts "Update failed :("
    end
  end
  
  
  
  
end