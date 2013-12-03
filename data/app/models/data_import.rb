class DataImport
  
  require 'csv'
    
  attr_accessor :filepath, :import_type, :options
  
  def initialize(filepath, import_type, options = {})
    @filepath = filepath
    valid_types = ['nypl_repo_uuid_by_mss_id','nypl_repo_objects_by_identifier']
    if valid_types.include?(import_type)
      @import_type = import_type
    else
      puts "Invalid value for import_type :("
      puts "Supported values for import_type are: " + valid_types.join(', ')
    end
    @options = options
    option_defaults =  { :clean => false, :format => 'csv' }
    option_defaults.each do |k,v|
      if !@options[k]
        @options[k] = option_defaults[k]
      end
    end
  end
  
  
  def execute
    
    case self.options[:format]
    when 'csv'
      rows = CSV.read(self.filepath)
    when 'tsv'
      rows = []
      File.open(self.filepath) do |f|
        f.each_line do |line|
          line.chomp!
          values = line.split(/\t/)
          rows << values
        end
      end
    end
    headers = rows.shift.map {|i| i.to_s }
    
    row_to_hash = lambda do |row,headers|
      row_hash = {}
      header_indices = {}
      headers.each { |h| header_indices[headers.index(h)] = h.to_sym }
      row.each do |v|
        index = row.index(v)
        row_hash[header_indices[index]] = v
      end
      return row_hash
    end
    
    
    import_nypl_repo_uuid_by_mss_id = Proc.new do |r,headers|
      mss_id_index = headers.index('mss_id')
      uuid_index = headers.index('uuid')
      if !r[mss_id_index].blank?
        # NOTE - This only works for components for now; no use case exists for collections, though this is supported in the model
        c = Component.where(:identifier_value => r[mss_id_index], :identifier_type => 'local_mss').first
        if c
          # destroy existing nypl_repo_objects before importing new data
          if self.options[:clean] && c
            c.nypl_repo_objects.each do |ro|
              ro.destroy
            end
          end
          if !r[uuid_index].blank?
            existing_object = NyplRepoObject.where(:uuid => r[uuid_index], :describable_id => c.id, :describable_type => 'Component').first
            if !existing_object
              ro = NyplRepoObject.new
              ro.describable_type = 'Component'
              ro.describable_id = c.id
              ro.uuid = r[uuid_index]
              ro.save
            end
          end
        else
          @errors << r[mss_id_index]
        end
      end
    end
    
    
    import_nypl_repo_objects_by_identifier = Proc.new do |r|
      row = row_to_hash.call(r,headers)
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
    
    
    case self.import_type
      
    when 'nypl_repo_uuid_by_mss_id'
      mss_id_index = headers.index('mss_id')
      uuid_index = headers.index('uuid')
      @errors = []
      rows.each do |r|
        import_nypl_repo_uuid_by_mss_id.call(r,headers)
      end
      if !@errors.blank?
        puts "These IDs are not in the system:"
        puts @errors.inspect
      end
    
    when 'nypl_repo_objects_by_identifier' 
      puts headers.inspect
      puts rows.length
      puts row_to_hash.call(rows.first,headers).inspect
      
      @duplicate_nypl_repo_objects = []
      @duplicate_components = []
      @creates = 0
      @updates = 0
      @no_uuid = 0
      
      rows.each do |r|
        import_nypl_repo_objects_by_identifier.call(r)
      end
      
      puts "Total nypl_repo_objects created/updated: #{creates.to_s}/#{updates.to_s}"
      if no_uuid > 0
        puts "#{@no_uuid} row(s) in the import file did not have uuid and were skipped"
      end
      if !@duplicate_nypl_repo_objects.blank? || !@duplicate_components.blank?
        puts "WARNING:"
        if !@duplicate_components.blank?
          puts "Duplicate components were found:"
          @duplicate_components.each { |dc| puts dc.join(', ') }
        end
        if !@duplicate_nypl_repo_objects.blank?
          puts "Duplicate existing nypl_repo_objects were found:"
          @duplicate_nypl_repo_objects.each { |dc| puts dc.join(', ') }
        end
      end
      
    end
    
    

    
  end
  
end
