module SharedMethods
  # These methods are shared between the Collection and Component models
  
  include NyplRepoSharedMethods
  include GeneralUtilityMethods
  include EadUtilityMethods
  include DataModelUtilityMethods
  include ControlledVocabularyUtilityMethods
  include DateUtilityMethods
  
  
  #############################################################
  # Retrieval & calculation methods
  #############################################################
  
  def description_data
    JSON.parse(self.description.data)
  end
  
  
  def abstract(data = nil)
    data ||= self.description_data
    abstract = data['abstract'] ? data['abstract'][0]['value'] : nil
  end


  def prefercite(data = nil)
    data ||= self.description_data
    prefercite = data['prefercite'] ? data['prefercite'][0]['value'].gsub!(/\<[^\>]*\>/,'').strip : nil
  end
 
  
  def unittitle(data = nil)
    data ||= self.description_data
    unittitle = data['unittitle'] ? data['unittitle'][0]['value'] : nil
  end
  
  
  def call_number_from_description
    data ||= self.description_data
    call_number = nil
    if data['unitid']
      data['unitid'].each do |u|
        if u['type'] == 'local_call'
          call_number = u['value']
          break
        end
      end
    end
    if !call_number && data['physloc']
      data['physloc'].each do |p|
        if p['type'] == 'local_call'
          call_number = p['value']
          break
        end
      end
    end
    call_number
  end
  
  
  def all_digital_objects
    digital_objects = {}
    self.nypl_repo_objects.each do |o|
      if o.capture_ids
        digital_objects[o.resource_type] ||= []
        captures = JSON.parse(o.capture_ids)
        digital_objects[o.resource_type].concat(captures)
      end
    end
    return digital_objects.empty? ? nil : digital_objects
  end
  
  
  def basic_unit_data(options = {})
    data = {}
    self.class.column_names.each { |a| data[a] = self[a] }
    data['type'] = self.class.to_s
    if data['type'] == 'Collection'
      org_unit = self.org_unit
    elsif data['type'] == 'Component'
      org_unit = self.collection.org_unit
      # get collection-level display attributes
    end
    data['org_unit_name'] = org_unit.name
    data['org_unit_name_short'] = org_unit.name_short ? org_unit.name_short : org_unit.name
    data['org_unit_code'] = org_unit.code
    
    data['digital_assets'] = self.total_nypl_repo_objects > 0 ? true : nil
    
    data
  end
  
  
  # Warning - the hash returned from this method has keys of mixed class (some strings, some symbols)
  def unit_data(options={})
    # stringify_keys on basic_unit_data to propery merge with description data
    unit_data = self.basic_unit_data.stringify_keys
    element_groups = []
    if !options[:basic]
      description = self.description
      if description && description.data
        desc_data = self.description_data
        
        # Origination is stored as a descriptiona attribute, but this should be replaced
        #  with controlled terms for better data management in the future
        origination = self.origination_associations
        if !origination.empty?
          desc_data['origination'] = []
          origination.each do |o|
            term_hash = o.term_hash
            term_hash[:value] = term_hash[:term]
            desc_data['origination'] << term_hash
          end
        end
        

        #add in any attached documents
        documents = Document.where(:describable_type => self.class.to_s, :describable_id => self.id)
        if documents
          if !desc_data['documents'] 
            desc_data['documents']  = []
          end
          documents.each do |l|
            desc_data['documents'] << { "document_type" => l['document_type'], "description" => l['description'], "title" => l['title'], "file" => l['file'] }
          end
        end


        #add any external links
        links = ExternalResource.where(:describable_type => self.class.to_s, :describable_id => self.id)
        if links
          if !desc_data['external_resources'] 
            desc_data['external_resources']  = []
          end
          links.each do |l|
            desc_data['external_resources'] << { "title" => l['title'], "description" => l['description'], "resource_type" => l['resource_type'], "url" => l['url'] }
          end
        end


        # remove anyting with internal == true
        desc_data.each do |k,v|
          if v.kind_of?(Array)
            v.each do |e|
              v.delete_if { |e| e.kind_of?(Hash) && e['internal'] }
            end
          end
        end
        compact(desc_data)
        
        unit_data.merge! desc_data
      end
    end

    if self.class == Collection
      unit_data['standard_access_note'] = self.org_unit.standard_access_note
    end
    unit_data
  end
  
  
  def resource_data
    resource_data = []
    
    # add documents if any
    if !self.documents.blank?
      self.documents.where('index_only != 1').each do |d|
        doc = d.attributes
        doc['url'] = d.file_url
        doc['file_type'] = doc['file'].split('.').last
        resource_data << doc
      end
    end
    
    # add external_resources if any
    if !self.external_resources.blank?
      self.external_resources.each { |r| resource_data << r.attributes }
    end
    
    delete_attributes = ['created_at','updated_at','describable_type','describable_id']
    
    resource_data.each do |r|
      delete_attributes.each { |k| r.delete(k) }
    end
    
    return resource_data.empty? ? nil : resource_data
  end
  
  
  def access_term_data(options = {})

    access_terms = {}
    # sort first, ask questions later
    
    associations = options[:controlaccess] ?
      self.access_term_associations.where(:controlaccess => true) : self.access_term_associations
        
    # turn associations into array so we can remove things from it more safely
    association_array = associations.to_a
    
    association_array.each do |a|
      term_hash = a.term_hash
      
      if name_elements.include?(term_hash[:type])
        (access_terms[term_hash[:type]] ||= []) << term_hash
      else
        case term_hash[:type]
        when 'genreform'
          (access_terms['genreform'] ||= []) << term_hash
        when 'geogname'
          (access_terms['geogname'] ||= []) << term_hash
        when 'title'
          (access_terms['title'] ||= []) << term_hash
        else
          if term_hash[:function] == 'occupation'
            (access_terms['occupation'] ||= []) << term_hash
          else
            (access_terms['subject'] ||= []) << term_hash
          end
        end
      end
    end
    access_terms['persname'] ||= []
    access_terms['persname'] += access_terms['name'] || []
    access_terms['name'] = access_terms['persname']
    access_terms['name'] += access_terms['famname'] || []
    access_terms['name'] += access_terms['corpname'] || []
    ['persname','famname','corpname'].each { |x| access_terms.delete(x) }
    
    # Sort names to ensure that creators come first
    sort_names = { 1 => [], 2 => [] }
    access_terms['name'].each do |n|
      if n[:function] == 'origination'
        sort_names[1] << n
      else
        sort_names[2] << n
      end
    end
    access_terms['name'] = sort_names[1] + sort_names[2]
    
    if options[:controlaccess]
      filter_controlaccess(access_terms)
    end

    compact(access_terms)
  end
  
  
  def origination_place
    places = []
    self.access_term_associations.each do |a|
      if a.function == 'origination_place'
        places << a.term_hash
      end
    end
    return !places.empty? ? places : nil
  end
  
  
  # Compiles unstructured physdesc values not included in extent_statement
  #   (which have supress_display=true in description.data)
  def physdesc_note
    data = self.description_data
    values = []
    if data['physdesc']
      data['physdesc'].each do |p|
        if !p['supress_display'] && p['value']
          values << {'value' => "<p>#{p['value']}</p>"}
        end
      end
    end
    return !values.empty? ? values : nil
  end
  
  
  def child_component_data
    children = self.children
    child_component_data = []
    children.each do |c|
      data = c.unit_data
      data['access_terms'] = c.access_term_data
      data['child_id'] = []
      c.children.each { |cc| data[:child_id] << cc.id }
      data.delete_if { |k,v| v.blank? }
      child_component_data << data
    end
    child_component_data
  end
  
  
  def all_component_data(level=nil)
    case self
    when Collection
      relation = Component.includes(:description,:access_term_associations).where(:collection_id => self.id)
      parent_id = nil
    when Component
      child_level = self.level_num + 1
      relation = Component.includes(:description,:access_term_associations).where(:collection_id => self.collection_id).where("level_num > #{self.level_num}")
      parent_id = self.id
    end
    i = 1
    
    get_child_component_data = lambda do |parent_id|
      
      children = relation.where(:parent_id => parent_id)
      if !children.empty?
        component_data = []
        children.each do |c|
          data = c.unit_data
          data['access_terms'] = c.access_term_data
          if c.has_children
            if level.nil? || level > i
              i += 1
              data['components'] = get_child_component_data.call(c.id)
            else
              data['child_id'] = []
              c.children.each { |cc| data['child_id'] << cc.id }
            end
          end

          if !c.has_children
            data['image_count'] = c.total_captures
          end
          
          data.delete_if { |k,v| v.blank? }
          component_data << data 
        end
        return component_data
      else
        return nil
      end
    end
    
    return get_child_component_data.call(parent_id)
    
  end
  
  
  def mods
    mods_export = ModsExport.new(:describable_type => self.class.to_s, :describable_id => self.id)
    mods_export.execute
  end
  
  
  ### Methods related to AccessTermAssociation relations ###
  
  def access_terms
    access_terms = []
    self.access_term_associations.each do |a|
      term = a.access_term
      term.name_subject = a.name_subject
      term.function = a.function
      access_terms << term
    end
    access_terms
  end
  
  
  # Returns access_term-associations with :function => 'origination'
  def origination_associations
    self.access_term_associations.where(:function => 'origination').
        order('access_term_associations.created_at ASC')
  end

  
  # Returns value for Solr unique_id field
  def unique_id
    "#{self.class.to_s.downcase}_#{self.id.to_s}"
  end
  
  
  
  
  #############################################################
  # Update methods
  #############################################################

  def add_object_attributes_from_description(data = nil)
    desc = JSON.parse(self.description.data)
    
    if desc['unittitle'] && desc['unittitle'][0]
      self.title ||= desc['unittitle'][0]['value']
    else
      self.title ||= ""
    end
    
    if desc['unitid'] && !self.identifier_value
      self.identifier_value = desc['unitid'][0]['value']
      self.identifier_type = desc['unitid'][0]['type']
    end
    
    if self.class == Collection && !self.call_number
      if desc['physloc']
        desc['physloc'].each do |p|
          if p['type'] == 'local_call'
            self.call_number = p['value']
            break
          end
        end
      end
      if !self.call_number && desc['unitid']
        desc['unitid'].each do |u|
          if u['type'] == 'local_call'
            self.call_number = u['value']
            break
          end
        end
      end
      if !self.call_number && desc['unitid']
        desc['unitid'].each do |u|
          if u['type'] == 'local_mss'
            self.call_number = "MssCol #{u['value']}"
            break
          end
        end
      end
    end
  end
  
  
  def update_title_and_origination(data = nil)
    if self.description
      data ||= self.description_data
      if data
        if !data['unittitle'].blank?
          title = data['unittitle'][0]['value']
          self.update_attributes(:title => title)
        end
        
        if !data['origination'].blank?
          origination = data['origination'][0]['value']
          self.update_attributes(:origination => origination)
        elsif !origination_associations.empty?
          originations = []
          origination_associations.each do |o|
            term = o.access_term
            name = term.term_authorized ? term.term_authorized : term.term_original
            if !name.blank?
              originations << name
            end
            if !originations.empty?
              self.update_attributes(:origination => originations.join('; '))
            end
          end
        end
      end
    end
  end
  
  
  def update_origination_from_term
    if !origination_associations.empty?
      origination = []
      origination_associations.each do |o|
        term_hash = o.term_hash
        term_hash[:value] = term_hash[:term]
        [:id, :term, :function, :questionable, :controlaccess].each { |x| term_hash.delete(x) }
        compact(term_hash)
        origination << term_hash
      end
      data = self.description_data
      data['origination'] = origination
      self.description.update_data(data)
    end
  end
  
  
  def update_date_statement(data = nil)
    data ||= self.description_data
    if data['unitdate']
      dates = {}

      data["unitdate"].each do |d|
        if d['type']
          (dates[d['type']] ||= []) << d['value']
        else
          (dates['other'] ||= []) << d['value']
        end
      end
      
      inclusive_dates_set = dates['inclusive'] || dates['other']
      
      if inclusive_dates_set && (inclusive_dates_set.length > 1)
        if data['dates_index']
          inclusive_date_string = integer_array_to_string(data['dates_index'])
        else
          inclusive_date_string = inclusive_dates_set.join('; ')
        end
      elsif inclusive_dates_set
        inclusive_date_string = inclusive_dates_set.first
      else
        inclusive_date_string = nil
      end
      
      if dates['bulk']
        bulk_date_string = dates['bulk'].first
      else
        bulk_date_string = nil
      end
      
      if inclusive_date_string && bulk_date_string
        self.date_statement = "#{inclusive_date_string} [bulk #{bulk_date_string}]"
      elsif inclusive_date_string && !bulk_date_string
        self.date_statement = inclusive_date_string
      elsif bulk_date_string
        self.date_statement = "bulk #{bulk_date_string}"
      end

    else
      self.date_statement = nil
    end
    self.save
  end
  
  
  def update_extent_statement(data = nil)
    
    get_physdesc_format = lambda do |physdesc|
      type = 'simple'
      physdesc.each do |p|
        if p['format'] == 'structured'
          type = 'structured'
          break
        end
      end
      return type
    end
    
    # Generate string for specific combinations of physdesc sub-elements
    structured_extent = lambda do |components|
      if (components.length > 1) && (components.length <= 3)
        names = []
        components.each { |c| names << c['name'] }
        names.sort!
        
        case names
        when ['dimensions','extent','physfacet'], ['extent','physfacet']
          extent_sort = { 'extent' => 0, 'physfacet' => 1, 'dimensions' => 2 }
        when ['dimensions','extent']
          extent_sort = { 'extent' => 0, 'dimensions' => 1 }
        when ['dimensions','physfacet']
          extent_sort = { 'physfacet' => 0, 'dimensions' => 1 }
        else
          extent_sort = nil
        end
        
        if extent_sort
          extent_parts = []
          components.each do |c|
            if extent_sort[c['name']]
              index = extent_sort[c['name']]
              extent_parts[index] = c['value'].gsub(/[\,\;\:]/,'').strip
            end 
          end
          return extent_parts.join(', ')        
        else
          return false
        end
      else
        return false
      end
    end

    data ||= self.description_data
    
    extents = []
    extent_statement = ''
    linear_feet = ''
    
    
    if data['physdesc']
      
      physdesc_format = get_physdesc_format.call(data['physdesc'])
      
      data['physdesc'].each do |p|
        p['supress_display'] = nil
        if (p['format'] == 'structured') && p['physdesc_components']
          structured = structured_extent.call(p['physdesc_components'])
          if structured 
            extents << structured
          else
            p['physdesc_components'].each do |pc|
              if pc['name'] == 'extent' && pc['value']
                extents << pc
              end
            end
          end
          p['supress_display'] = true
        end
      end
      
      # case physdesc_format
      # when 'structured'
      #   data['physdesc'].each do |p|
      #     if (p['format'] == 'structured') && p['physdesc_components']
      #       structured = structured_extent.call(p['physdesc_components'])
      #       if structured 
      #         extents << structured
      #       else
      #         p['physdesc_components'].each do |pc|
      #           if pc['name'] == 'extent'
      #             extents << pc
      #           end
      #         end
      #       end
      #       p['supress_display'] = true
      #     end
      #   end
      #   
      # when 'simple'
      #   data['physdesc'].each do |p|
      #     if (p['format'] == 'simple') && p['value']
      #       extents << p['value'].strip
      #       p['supress_display'] = true
      #     end
      #   end
      # end

    end
    

    

    lf_regex = /[Ll](in(ear)?\.?\s?)?[Ff]([eo]*t\.?)?/
    lf_sub_regex = /[Ll](in(ear)?\.?\s?)?[Ff]([eo]*t\.?)?.*$/
    
    extents.each_index do |i|
      e = extents[i]
      if e.class == String
        value = e
        if value.match(lf_regex)
          linear_feet = value.gsub(lf_sub_regex,'').strip
        end
      else
        if (e['unit'] && e['unit'] == 'linear feet') || (e['value'] && e['value'].match(lf_regex))
          value = e['value'].strip
          if !value.match(lf_regex)
            value += (value == '1') ? " linear foot" : " linear feet"
          end
          linear_feet = e['value'].gsub(lf_sub_regex,'').strip
        else
          value = e['value']
        end
      end
      
      value.strip!
      value.gsub!(/[\,\;\-\+\&]$/,'')
      value.gsub!(/(?<!\s\w{2})\.$/,'')
      value.strip!
      
      # Only display up to 3 additional extents
      case i
      when 0
        extent_statement += value
      when 1
        extent_statement += " (#{value}"
      when 2, 3
        extent_statement += "; #{value}"
      end
      if (extents.length > 1) && (e == extents.last)
        extent_statement += ")"
      end
      
    end
    linear_feet.gsub!(/[^\d\.]/,'')
    lf_replace = linear_feet == '1' ? 'linear foot' : 'linear feet'
    extent_statement.gsub!(lf_regex,lf_replace)
    
    self.update_attributes(:extent_statement => extent_statement.blank? ? nil : extent_statement,
      :linear_feet => linear_feet.blank? ? nil : linear_feet.to_f)
    
    # Save description to store new supress_display attributes
    data['extent_statement'] = extent_statement.blank? ? nil : extent_statement
    compact(data)
    self.description.update_data(data)
  end
  

  
  def date_statement_cleanup
    if self.date_statement
      new_date_statement = self.date_statement.clone
      if self.date_statement.match(/bulk\sbulk/)
        new_date_statement.gsub!(/bulk\sbulk/,'bulk')
      end
      if self.date_statement.match(/\,\s\[bulk/)
        new_date_statement.gsub!(/\,\s\[bulk/,' [bulk')
      end
      new_date_statement.gsub!(/\[bulk\sdates/,'[bulk')
      new_date_statement.gsub!(/\[bulk\s?\(\s?/,'[bulk ')
      new_date_statement.gsub!(/\s?\(bulk\]$/,']')
      new_date_statement.gsub!(/circa/,'ca.')
      new_date_statement.gsub!(/\(inclusive(\sdates)?\)/,'')
      new_date_statement.gsub!(/\]\-/,'-')
      new_date_statement.gsub!(/\s?\/\s?$/,'')
      new_date_statement.gsub!(/\s{2,}/,' ')
      if new_date_statement != self.date_statement
        self.update_attribute(:date_statement, new_date_statement)
      end
    end
  end
  
  
  # Remove remnants of dates from titles, both in object attributes and in unititle within description data
  def remove_date_from_title(data = nil)
    
    title = self.title || ''
    date_statement = self.date_statement || ''
      
    strip_title_elements = lambda do |title, date_statement|
      new_title = title.clone
      if date_statement
        new_title.gsub!(date_statement,'')
      end
      new_title.strip!
      new_title.gsub!(/[\;\,\.]*$/,'')
      
      artifacts_regex = /\,?\s(ca\.?)?\s?(and)?\s?$/
      artifacts_regex2 = /^\s?(ca\.?)?(and)?\s?$/
      new_title.gsub!(artifacts_regex,'')
      new_title.gsub!(artifacts_regex2,'')
      return new_title.blank? ? nil : new_title
    end
    
    if self.title
      new_title = strip_title_elements.call(title, date_statement)
      puts new_title
      self.update_attributes(:title => new_title)
    end   
    
    data ||= self.description_data
    
    if data['unittitle']
      data['unittitle'].each do |u|
        if u['value']
          new_title = strip_title_elements.call(u['value'], date_statement)
          u['value'] = new_title
        end
      end
      self.description.update_attributes(:data => JSON.generate(data))
    end
    
  end

  ### END - Methods to update object attributes ###
  
  
  
  
  #############################################################
  # Search index methods
  #############################################################
  
  
  def solr_doc_hash
    
    puts "preparing data for #{self.class.to_s} #{self.id.to_s}"
    
    @doc = {}
    case self
    when Collection
      object_attributes = collection_attributes
    when Component
      object_attributes = component_attributes
    end
    object_attributes.each do |a|
      attribute_value = self.send(a)
      if attribute_value
        @doc[a] = attribute_value
      end
    end
    
    # keys frojm description will be strings, so make them all strings to avoid problems
    @doc.stringify_keys!
    
    if @doc['identifier_value'] && (@doc['identifier_type'] == 'local_mss')
      @doc['mss_id'] = @doc['identifier_value']
    end
    
    if self.origination
      @doc['origination_ss'] = self.origination
    end
    
    @doc['type'] = self.class.to_s.downcase
    self.generate_solr_unique_id
    self.generate_solr_origination_fields
    self.generate_solr_association_fields
    self.generate_solr_component_path if self.class == Component
    self.generate_solr_access_fields
    self.generate_solr_date_fields
    self.generate_solr_description_fields
    self.generate_solr_boost_queries
    @doc.each do |k,v|
      if v.class == Array
        v.uniq!
      end
    end
    
    # for collections with no components/EAD, index PDF text
    if self.class == Collection
      if self.components.blank?
        self.generate_solr_pdf_content
      end
    end
    
    compact(@doc)
  end
  
  
  # make orignation fields (will overwrite origination generated from object attributes)
  def generate_solr_origination_fields
    if defined?(@doc)
      @doc['origination'] = []

      origination_associations = self.origination_associations
      
      if !origination_associations.empty?
        origination_associations.each do |o|
          @doc['origination'] << o.term_hash[:term]
        end
      elsif self.origination
        @doc['origination'] << self.origination
      end
      
      if !@doc['origination'].empty?
        @doc['origination_ss'] = @doc['origination'].first
      end
      @doc['origination'].uniq!
    end
  end
  
  
  def generate_solr_unique_id
    if defined?(@doc)
      @doc['unique_id'] = self.unique_id
    end
  end
  
  
  def generate_solr_association_fields
    if defined?(@doc)
      if self.class == Collection
        org_unit = self.org_unit
        @doc['collection_id'] = self.id
      elsif self.class == Component
        org_unit = self.collection.org_unit
        # get collection-level display attributes
        @doc['collection_title'] = self.collection.title
        @doc['collection_date_statement'] = self.collection.date_statement
        @doc['collection_extent_statement'] = self.collection.extent_statement
        @doc['collection_call_number'] = self.collection.call_number
        @doc['collection_abstract'] = self.collection.description.abstract
        @doc['collection_identifier_value'] = self.collection.identifier_value
        @doc['collection_org_unit_id'] = self.collection.org_unit_id
        @doc['collection_origination'] = self.collection.origination
        if self.parent_component
          @doc['parent_title'] = self.parent_component.title
        end
      end
      @doc['org_unit_name'] = org_unit.name
      @doc['org_unit_code'] = org_unit.code
      
      # digitized content (nypl_repo_objects association)
      if self.total_nypl_repo_objects > 0
        @doc['digital_assets'] = true
      end
    end
  end

  
  # returns array of all anscestor component titles, in ascending order by level
  def generate_solr_component_path
    if defined?(@doc)
      component_path = []
      self.component_ancestors.each { |a| component_path << a.title }
      @doc['component_path'] = component_path
    end
  end
  
  
  def generate_solr_access_fields
    if defined?(@doc)
      self.access_term_associations.each do |a|
        term = a.access_term.term_authorized ? a.access_term.term_authorized : a.access_term.term_original
        (@doc['access_terms'] ||= []) << term
        (@doc['access_term_id'] ||= []) << a.access_term.id
        case a.access_term.term_type
        when 'persname','corpname','famname','name'
          (@doc['access_name'] ||= []) << term
        when 'genreform'
          (@doc['access_genreform'] ||= []) << term
        when 'geogname'
          (@doc['access_geogname'] ||= []) << term
        when 'subject','topic'
          (@doc['access_subject'] ||= []) << term
        when 'title'
          (@doc['access_title'] ||= []) << term
        end
        
        if a.access_term.function == 'occupation'
          (@doc['access_occupation'] ||= []) << term
        elsif a.access_term.function == 'origination'
          (@doc['origination_term_id'] ||= []) << a.access_term.id
        end
      end
      @doc.stringify_keys!
    end
  end
  
  
  # call on instance of Description
  # will return nil if called outside the context of genrating a has of values passed in a solr update request
  def generate_solr_date_fields
    if defined?(@doc) && self.description && self.description.data
      data = JSON.parse(self.description.data)
      # puts 'generate_solr_date_fields'
      # puts date_fields.inspect
      date_fields.each do |f|
        if data[f]
          if f == 'keydate'
            @doc['keydate'] = date_to_zulu(data[f].to_s)
          else
            @doc[f] = data[f]
          end
          
          if f == 'dates_index'
            decades = []            
            data[f].each do |d|
              decade = d - (d % 10)
              if (decade > 0) && !decades.include?(decade)
                decades << decade
              end
            end
            @doc['dates_decade'] = decades if !decades.blank?
          end
        end

      end      
    end
  end

  
  def generate_solr_description_fields
    if defined?(@doc) && self.description
      puts 'generate_solr_description_fields'
      if self.description.data
        data = JSON.parse(self.description.data)
        data.each do |k,v|
          if date_fields.include?(k)
            next
          else
            case k
            when 'physdesc'
              generate_solr_physdesc(v)
            when 'unitid'
              generate_solr_unitid(v)
            when 'langmaterial_code'
              @doc['langmaterial_code'] = v
              v.each do |l|
                language = language_string_to_code.key(l)
                (@doc['langmaterial_name'] ||= []) << language if language
              end
            when 'container'
              v.each do |c|
                doc_key = c['type'] ? "container_#{c['type']}" : 'container'
                @doc[doc_key] ||= []
                @doc[doc_key] << c['value']
              end
            else
              if !@doc[k]
                @doc[k] = []
                v.each do |vv|
                  @doc[k] << vv['value'] if vv['value']
                end
              end
            end
          end
        end
      end      
    end
  end
  
  
  def generate_solr_unitid(value_array)
    if defined?(@doc)
      value_array.each do |unitid|
        if unitid['type']
          (@doc["unitid_#{unitid['type']}"] ||= []) << unitid['value']
        else
          (@doc['unitid'] ||= []) << unitid['value']
        end
      end
    end
  end
  
  
  def generate_solr_physdesc(value_array)
    if defined?(@doc)
      
      value_array.each do |physdesc|
        case physdesc['format']
        when 'simple', nil
          (@doc['physdesc'] ||= []) << physdesc['value']
        when 'structured'
          physdesc['physdesc_components'].each do |pc|
            key = "physdesc_#{pc['name']}"
            (@doc[key] ||= []) << pc['value']
          end
        end
      end
    end
  end
  

  def generate_solr_pdf_content
    require 'open-uri'
    
    if defined?(@doc) && (self.class == Collection) &&
      self.pdf_finding_aid || ((self.amat_record && self.amat_record.pdf_url) || !self.documents.where(:index_only => true).empty?)
      
      # puts 'generate_solr_pdf_content'
      
      begin
        work_directory = Rails.root.join('tmp').to_s
        
        if !self.documents.where(:index_only => true).empty?
          pdf_filename = nil
          doc = self.documents.where(:index_only => true).first
          file = open("#{Rails.root}/public#{doc.file_url}")
          puts 'Indexing text file instead of PDF'
        else
          if self.pdf_finding_aid
            url = self.pdf_finding_aid_url
          elsif self.amat_record && self.amat_record.pdf_url
            url = self.amat_record.pdf_url
          else
            # No PDF
            return nil
          end
          pdf_filename = url.split('/').last
          spec = pdf_filename.sub(/.pdf$/, '')
          txt_filename = "#{spec}.txt"
          local_pdf_path = "#{work_directory}/#{pdf_filename}"
        
          # pdftotext only works for local files, so temporarily copy remote PDF to local directory
          open(local_pdf_path, 'wb') do |file|
            file << open(url).read
          end
        
          # run pdftotext and get the txt file it generates
          `pdftotext #{local_pdf_path} -enc UTF-8`
        
          file = File.new("#{work_directory}/#{txt_filename}")
        end  
        
        text = ''

        file.readlines.each do |l|
          begin
            l.chomp!
            if l.length > 0
              # Remove extraneous text....
              # Common finding aid words
              stop_words = [
                /[Ff]ile\s/, /[Ff]older\s/, /[Bb]ox\s/,
                /([Ss]ub\-?)?[Ss]eries/, /\s[Pp]\.\s/, /\s[Se][Ee]{2}\:?\s/,
                /\s[Se][Ee]{2}\s[Aa]lso\:?\s/, /\sn\.d\.[\s\n\r]+/, /\s[Nn]o\.?\s/,
                /[Cc]orrespondence/,  /\s\(?continued\)?\s/
              ]
              stop_words.each { |x| l.gsub!(x,' ') }
            
              # Numbers and number ranges (inline)
              l.gsub!(/(\s[\d\-]+)+/,' ')
              # Numbers and number ranges (full line)
              l.gsub!(/^[\s\d\-]+$/,' ')
              # tab filler characters
              l.gsub!(/[\.\-]{2,}/,' ')
              # (some) roman numerals
              l.gsub!(/\s[IVXL]+\.\s/, ' ')
      
              # double punctuation (left from prior subs)
              punctuation = '\.\,\;\:\]\[\)\(\-'
              2.times do
                # l.gsub!(Regexp.new('(\s[' + punctuation + ']+\s[' + punctuation + ']*\s?)+'),' ')
                l.gsub!(/(\s[^\w\d\s]+\s[^\w\d\s]*\s?)+/,' ')
              end
              text += l
            end
          rescue Exception => e
            puts e
          end
        end
        
        file.close
        
        split_paragraphs = lambda do |string|
          string.gsub!(/\<\/p\>/,'')
          string.gsub!(/^\<p\>/,'')
          parts = string.split('<p>')
          parts.each { |t| t.strip! }
          parts
        end
        
        # terms already indexed in other fields
        already_indexed = []
        
        @doc.each do |k,v|
          if v.class == Array
            v.each { |value| already_indexed += split_paragraphs.call(value.to_s) if !value.blank? }
          else
            already_indexed += split_paragraphs.call(v.to_s) if !v.blank?
          end
        end
        
        already_indexed.uniq!
        already_indexed.each { |x| text.gsub!(x,' ') }
        
        # remove new lines and multiple spaces
        text.gsub!(/[\s\n\r\t]+/,' ')
        text.gsub!(/\s{2,}/,' ')
            
        # remove pdf and txt file from local directory
        `cd #{work_directory}; rm -rf #{pdf_filename}; rm -rf #{txt_filename}`
  
        @doc[:pdf_content] = text
        
      rescue Exception => e
        puts e
      end
      
    end
  end
  
  
  def generate_solr_boost_queries
    if defined?(@doc) && !self.boost_queries.blank?
      queries = JSON.parse(self.boost_queries)
      # Make sure this is an array, just in case
      if queries.kind_of? Array
        @doc['boost_query'] = queries
      end
    end
  end
  



  #############################################################
  # Protected methods
  #############################################################

  
  protected
  
  
  def filter_controlaccess(access_terms)

    access_terms.each do |type,array|
      array.each do |term|
        if !term[:controlaccess]
          array.delete(term)
        end
      end
      if array.empty?
        access_terms.delete(type)
      end
    end
    
    #test
    access_terms.each { |a| puts a.inspect }
    
    # Remove duplicates (these occur when the same name is included in MARC 6xx and 7xx fields)
    access_terms.each do |type, a|
      term_ids = []
      a.each_index do |i|

        term_hash = a[i]

        if !term_ids.include? term_hash[:id]
          term_ids << term_hash[:id]
        else
          a.delete_at i
        end
      end
    end
    
    #test
    access_terms.each { |a| puts a.inspect }
    
    access_terms
  end
  
end
