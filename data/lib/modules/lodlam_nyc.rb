module LodlamNyc
  
  def generate_collection_json(collection_id)
        
    c = Collection.find collection_id
    data_raw = c.description.data
    data = JSON.parse(data_raw)
    json_hash = {}
    json_hash['title'] = c.title
    (json_hash['extent'] ||= []) << c.extent_statement if c.extent_statement
    json_hash['data_original'] = data_raw
    
    json_hash['identifier_value'] = c.call_number
    json_hash['identifier_type'] = 'nypl_call'
    
    simple_data_values = {
      'abstract' => 'abstract',
      'prefercite' => 'bibliographicCitation',
      'accessrestrict' => 'access',
      'custodhist' => 'provenance',
      'scopecontent' => 'description'
    }

    simple_data_values.each do |k,v|
      if data[k]
        data[k].each do |x|
          (json_hash[v] ||= []) << x['value']
        end
      end
    end
    
    if data['langmaterial_code']
      data['langmaterial_code'].each { |l| (json_hash['language'] ||= []) << l }
    end
    
    c.access_term_associations.each do |a|
      access_term = a.access_term
      term_types = {
        'persname' => 'person',
        'corpname' => 'corporate body',
        'famname' => 'family',
        'name' => nil,
        'subject' => 'topic',
        'genreform' => 'form genre',
        'title' => 'title',
        'geogname' => 'geographic',
        'topic' => 'topic',
        'occupation' => 'topic'
      }
      term = {
        'label' => access_term.term_authorized ? access_term.term_authorized : access_term.term_original,
        'type' => term_types[access_term.term_type]
      }
      term['authority'] = access_term.authority if access_term.authority
      case access_term.term_type
      when 'persname','corpname','famname','name'
        term['entity_type'] = term.delete('type')
        if a.role
          term['association_type'] = a.role
        elsif a.function == 'origination'
          term['association_type'] = 'origination'
        end
        (json_hash['entities'] ||= []) << term
      when 'subject','genreform','title','geogname','topic','occupation'
        term['topic_type'] = term.delete('type')
        (json_hash['topics'] ||= []) << term
      end
    end
    
    json = JSON.generate(json_hash)
    
  end
  
  
  # filepath points to a newline-separated list of collection ids
  def generate_bulk_json(filepath)
    filename = filepath.split('/').last
    filename_stub = filename.split('.').first
    export_filepath = filepath.gsub(filename,"#{filename_stub}_bulk_import.json")
    json = File.new(export_filepath,'w')
    json << '{"data":['
    source = File.new(filepath)
    i = 0
    source.each_line do |l|
      json << ',' if i != 0
      collection_id = l.strip
      json << generate_collection_json(collection_id)
      i += 1
    end
    source.close
    json << ']}'
    json.close
  end
  
end