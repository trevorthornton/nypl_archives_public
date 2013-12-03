module DataImportMethods
  
  def row_to_hash(row,headers)
    row_hash = {}
    keys = headers.map { |h| h.to_sym }
    row.each_index do |i|
      value = row[i]
      if value.class == String
        value.force_encoding('UTF-8')
        value.strip!
      end
      row_hash[keys[i]] = value
    end
    return row_hash
  end
  
  
  def import_nypl_repo_uuid_by_mss_id(row,headers)
    mss_id_index = headers.index('mss_id')
    uuid_index = headers.index('uuid')
    if !row[mss_id_index].blank?
      # NOTE - This only works for components for now; no use case exists for collections, though this is supported in the model
      c = Component.where(:identifier_value => row[mss_id_index], :identifier_type => 'local_mss').first
      if c
        # destroy existing nypl_repo_objects before importing new data
        if self.options[:clean] && c
          c.nypl_repo_objects.each do |ro|
            ro.destroy
          end
        end
        if !row[uuid_index].blank?
          existing_object = NyplRepoObject.where(:uuid => r[uuid_index], :describable_id => c.id, :describable_type => 'Component').first
          if !existing_object
            ro = NyplRepoObject.new
            ro.describable_type = 'Component'
            ro.describable_id = c.id
            ro.uuid = row[uuid_index]
            ro.save
          end
        end
      else
        @errors << row[mss_id_index]
      end
    end
  end
  
  
  def import_nypl_repo_objects_by_identifier(row,headers)
    row = row_to_hash(row,headers)
    component_where = { :identifier_value => row[:identifier_value], :identifier_type=> row[:identifier_type] }
    components = Component.where(component_where)
    if components.length > 1
      component_ids = []
      components.each { |c| component_ids << c.id }
      duplicate_components << component_ids
    end
    if components.first
      component = components.first
      existing_nypl_repo_objects = NyplRepoObject.where(:describable_type => 'Component', :describable_id => component.id)
      if existing_nypl_repo_objects.length > 1
        nypl_repo_object_ids = []
        existing_nypl_repo_objects.each { |r| nypl_repo_object_ids << r.id }
        duplicate_nypl_repo_objects << nypl_repo_object_ids
      end
      if existing_nypl_repo_objects.first
        nypl_repo_object = existing_nypl_repo_objects.first
        action = 'update'
      else
        nypl_repo_object = NyplRepoObject.new(:describable_type => 'Component', :describable_id => component.id)
        action = 'create'
      end
      # "uuid", "object_type", "capture_ids", "total_captures"
      nypl_repo_object[:uuid] = row[:uuid]
      nypl_repo_object[:capture_ids] = row[:capture_ids]
      nypl_repo_object[:total_captures] = row[:total_captures].to_i
      if nypl_repo_object[:uuid]
        nypl_repo_object.save
        case action
        when 'update'
          updates += 1
        when 'create'
          creates += 1
        end
      else
        no_uuid += 1
      end
    end
  end
  
  
end