class EadIngest < ActiveRecord::Base
  
  include IngestUtilityMethods
  
  attr_accessible :filepath, :org_unit_id
  
  has_one :collection
  
  attr_accessor :filepath, :org_unit_id, :collection_id, :update, :active
  
  def execute
    if self.filepath.nil? || self.filepath.nil?
      return "Before executing ingest, you must specify filepath to EAD and the org_unit id for the holding division."
    else
      if @source = open(filepath)
        @contents = @source.read
        @doc = Nokogiri::XML(@contents)
        # remove namespaces
        @doc.remove_namespaces!
        @ead = @doc.root()
        if !@ead.nil?
          @frontmatter = @ead.xpath('./frontmatter').first
          @archdesc = @ead.xpath('./archdesc').first
          @dsc = @archdesc.xpath('.//dsc').first
          if self.process_collection_data
            if !self.collection_id
              self.collection_id = @collection.id
            end
            self.save
            @collection.reload
            @collection.post_ingest_updates(:skip_components => self.update == 'collection' ? true : nil)
            # update search index on update only (new collections need to be added to index manually for now)
            puts "Collection successfully ingested :)"
            puts "You should update the search index."
          else
            return "An application error was encountered when processing the collection data :("
          end
        else
          return "The file you are attempting to ingest does not appear to be a valid EAD document - operation aborted :("
        end
      else
        return "Could not open file :("
      end
    end
  end
  
  
  def process_collection_data
    if !self.update
      @collection = Collection.new
      @collection.org_unit_id = self.org_unit_id
      @collection.active = self.active || true
      @collection.description = Description.new(:describable_type => 'Collection')
    else
      if !self.collection_id
        puts "NO COLLECTION ID :("
        return false
      elsif !['collection','all'].include?(self.update)
        puts "ONLY ALLOWED VALUES FOR @update ARE 'collection' and 'all' :("
        return false
      else
        @collection = Collection.find self.collection_id
        if self.update == 'all'
          
          @old_components = []

          # On update, existing components must be tracked as they are updated
          # so that existing components not present in the current ingest can be deleted later
          Component.find_each(:conditions => "collection_id = #{self.collection_id}") { |c| @old_components << c.id }
          
          # test
          @old_component_count = @old_components.length
          
        end
      end
    end
    
    puts @collection.inspect
    
    # collection_level_data = archdesc with all components removed
    # EAD_REVISION - dsc is being removed, so this will stop working :(
    collection_level_data = @archdesc.clone
    collection_level_data.xpath('./dsc').each { |dsc| dsc.remove }    
        
    @collection.description.descriptive_identity = parse_descriptive_id_elements(collection_level_data)
    @collection.description.context = parse_context_elements(collection_level_data)
    @collection.description.content_structure = parse_content_structure_elements(collection_level_data)
    @collection.description.access_use = parse_access_use_elements(collection_level_data)
    @collection.description.acquisition_processing = parse_acquisition_processing_elements(collection_level_data)
    @collection.description.related_material = parse_related_material_elements(collection_level_data)
    @collection.description.notes = parse_notes(collection_level_data)
    @collection.add_object_attributes_from_descriptive_identity
    
    # for updates, save description (on create this happens automagically)
    @collection.description.save if self.update
        
    if @collection.save
      puts "COLLECTION SAVED :)"
      if self.update != 'collection'
        # WARNINGS: dsc is going away in EAD revision
        parse_dsc if @dsc
      end
    else
      puts "COLLECTION NOT SAVED :("
      return false
    end
    
    # on updates, delete existing access_term-associations before processing access terms
    if self.update
      @collection.access_term_associations.each { |ata| ata.destroy }
    end
    process_controlaccess(collection_level_data, @collection.id, 'Collection')
    
    
    # test
    if self.update == 'all'
      puts "COMPONENT DELETION DATA"
      puts @old_component_count
      puts @old_components.length
    end
    
    
    if !@old_components.blank?
      @old_components.each do |cid|
        c = Component.find cid
        c.destroy
        puts "DESTROY #{@old_components.index(cid).to_s}"
      end
      Component.reset_auto_increment
    end
    
    return true
  end
  

  # EAD_REVISION - dsc is being removed, so this will stop working :(
  # Probable no-dsc solution is to start with <c> or <c01> that are children of <archdesc>
  def parse_dsc
    components_top = get_child_components(@dsc)
    @component_count = 0
    sib_seq = 1
    components_top.each do |c|
      process_component(c, {:index => 0, :sib_seq => sib_seq})
      sib_seq += 1
    end
    puts "Total components: #{@component_count.to_s}"
    @collection.components.each { |c| c.update_has_children }
  end

  
  # NOTE: this method is recursive
  # element is an EAD component element (<c> or one of <c01> ... <c12>)
  # options[:index] is the 0-based level of the element
  # options[:parent_id] is the database id for the parent component, if applicable
  def process_component(element, options = {})
    
    # collection_level_data will include all elements contained in this componenet, but none of its subcomponents
    component_level_data = element.clone
    all_components_xpath = ".//c|.//c01|.//c02|.//c03|.//c04|.//c05|.//c06|.//c07|.//c08|.//c09|.//c10|.//c11|.//c12"
    component_level_data.xpath(all_components_xpath).each { |c| c.remove }
    
    @component_count += 1
    component = Component.new
    
    component.collection_id = @collection.id
    component.level_num = options[:index] + 1
    component.level_text = element['level']
    component.parent_id = options[:parent_id]
    component.sib_seq = options[:sib_seq]
    
    # For now, all org_unit_id for components is the same as collection
    # Consider cases where certain components are controlled by different divisions - is there such a thing?
    component.org_unit_id = @collection.org_unit_id
    
    component.description = Description.new(:describable_type => 'Component')
    component.description.descriptive_identity = parse_descriptive_id_elements(component_level_data)
    component.description.context = parse_context_elements(component_level_data)
    component.description.content_structure = parse_content_structure_elements(component_level_data)
    component.description.acquisition_processing = parse_acquisition_processing_elements(component_level_data)
    component.description.related_material = parse_related_material_elements(component_level_data)
    component.description.access_use = parse_access_use_elements(component_level_data)
    # add notes
    
    component.add_object_attributes_from_descriptive_identity
    
    
    update_existing_component = Proc.new do |existing,component|
      existing.collection_id = component.collection_id
      existing.level_num = component.level_num
      existing.level_text = component.level_text
      existing.parent_id = component.parent_id
      existing.sib_seq = component.sib_seq
      existing.description.descriptive_identity = component.description.descriptive_identity
      existing.description.context = component.description.context
      existing.description.content_structure = component.description.content_structure
      existing.description.acquisition_processing = component.description.acquisition_processing
      existing.description.related_material = component.description.related_material
      existing.description.access_use = component.description.access_use
      existing.add_object_attributes_from_descriptive_identity
    end
    
    
    # check for existing component based on identifier_value/identifier_type
    existing_component = Component.where(
      :identifier_value => component.identifier_value,
      :identifier_type => component.identifier_type).first
    
    if existing_component
      update_existing_component.call(existing_component,component)
      current_component = existing_component
      current_component.save
      current_component.description.save
      if defined?(@old_components)
        @old_components.delete(current_component.id)
      end
    else
      current_component = component
      current_component.save
    end
    
    puts "Component #{@component_count.to_s}"
    
    process_controlaccess(component_level_data, current_component.id, 'Component')
    
    children = get_child_components(element,options[:index] + 1)
    if !children.nil?
      sib_seq = 1
      children.each do |c|
        process_component(c, {:index => options[:index] + 1, :parent_id => current_component.id, :sib_seq => sib_seq})
        sib_seq += 1
      end
    end
    
  end
    
  
  # EAD_REVISION - elements for controlled access terms may be split into block-level and inline versions
  def process_controlaccess(parent_element, describable_id, describable_type)
    
    process_terms = lambda do |element_set|
      access_terms = {}
      element_set.each do |e|
        access_terms[e.inner_text] ||= {}
        if e['source']
          access_terms[e.inner_text][:authority] = e['source'] == 'lcnaf' ? 'naf' : e['source']
        end
        
        if e['authfilenumber']
          if e['authfilenumber'].match(/^http:/)
            access_terms[e.inner_text][:value_uri] = e['authfilenumber']
          else
            access_terms[e.inner_text][:authority_record_id] = e['authfilenumber']
          end
        end
        
        if e['role']
          access_terms[e.inner_text][:role] = e['role']
        end
        
        access_terms[e.inner_text][:term_type] = e.name
        access_terms[e.inner_text][:term_original] = remove_newlines(e.inner_text)
        
        # OK, here's the thing: Some names are subjects.
        # In our current EADs, this is indicated by including a persname, corpname or famname within a nested controlaccess that includes this:
        # <head>Subjects:</head>
        # Not great, but that's what we've got. So we look for that, and if it's there, set name_subject to true        
        if name_elements.include?(e.name)
          head = e.xpath('preceding-sibling::head').first
          if head
            if head.inner_text.match(/[Ss]ubject/)
              access_terms[e.inner_text][:name_subject] = true
            end
          end
        end
        
      end
      return access_terms
    end
    
    save_terms_and_associations = Proc.new do |access_terms, controlaccess|
      access_terms.each do |k,v|
        # v = hash of params
        
        # extract relation params from term hash
        association_params = {}
        if v[:role]
          association_params[:role] = v[:role]
          v.delete(:role)
        end
        association_params[:controlaccess] = controlaccess
        
        existing_term = AccessTerm.where(v).first
        if !existing_term
          t = AccessTerm.new(v)
          puts t.inspect
          t.save
        else
          t = existing_term
        end
        
        association_query_params = {
          :access_term_id => t.id,
          :describable_type => describable_type,
          :describable_id => describable_id
        }

        existing_term_association = AccessTermAssociation.where(association_query_params).first
        
        association_params.merge!(association_query_params)
        
        if !existing_term_association
          association_params[:controlaccess] = controlaccess
          AccessTermAssociation.create(association_params)
        else
          existing_term_association.update_attributes(association_params)
        end
        
      end
    end
    
    controlaccess = parent_element.xpath('.//controlaccess').first
    access_elements_xpath = './/'
    access_elements_xpath += access_elements.join('|.//')
    
    controlaccess_element_set = controlaccess ? controlaccess.xpath(access_elements_xpath) : nil
    # other_terms_element_set = all terms in parent not included in controlaccess
    # (controlaccess elements are removed below)
    other_terms_element_set = parent_element.xpath(access_elements_xpath)
    
    if controlaccess_element_set
      access_terms = process_terms.call(controlaccess_element_set)
      save_terms_and_associations.call(access_terms,true)
      controlaccess_element_set.each { |n| other_terms_element_set.delete(n) }
    end
    
    if other_terms_element_set.length > 0
      other_access_terms = process_terms.call(other_terms_element_set)
      save_terms_and_associations.call(other_access_terms,false)
    end

  end

  
  def add_attributes_to_element_hash(element, element_hash)
    element.attributes.each do |k,v|
      if !element_hash.has_key?(k) && !skip_attributes.include?(k)
        element_hash[k] = element[k]
      end
    end
    element_hash
  end
  
  
  # Parse Descriptive Identity elements
  # returns JSON
  def parse_descriptive_id_elements(parent_element, level = 'collection')
    @desc_data = {}
    # elements = 'unitid','repository','unittitle','unitdate','physdesc','materialspec','abstract','langmaterial','odd','prefercite','note'
    parse_unitid(parent_element, level)
    parse_unitdate(parent_element, level) 
    parse_unittitle(parent_element, level)      
    parse_physdesc(parent_element, level)      
    parse_other_descriptive_elements(parent_element, level)
    # parse_did_note(parent_element, level)
    return !@desc_data.blank? ? JSON.generate(@desc_data) : nil
  end
  
  
  # parse unitid
  def parse_unitid(parent_element, level = 'collection')
    unitid = parent_element.xpath('.//unitid')
    if unitid.length > 0
      @desc_data['unitid'] = []
      unitid.each do |e|
        edata = {}
        if e.inner_text.match(/(MssCol)|(msscol)/)
          edata['value'] = e.inner_text.gsub(/[^\d]/,'')
          edata['type'] = 'local_mss'
        else
          edata['value'] = e.inner_text
          edata['type'] = e['type']
        end
        add_attributes_to_element_hash(e, edata)
        @desc_data['unitid'] << edata
      end
    end
  end

  
  # parse unittitle
  def parse_unittitle(parent_element, level = 'collection')
    unittitle = parent_element.xpath('.//unittitle')
    if unittitle.length > 0
      @desc_data['unittitle'] = []
      unittitle.each do |e|
        # Clone element because we have to strip out the nested unitdate, which we might need later
        ee = e.clone
        # remove nested unitdate
        nested_dates = ee.xpath('./unitdate')
        if nested_dates.length > 0
          nested_dates.each do |d|
            d.remove
          end
        end
        # strip and remove trailing comma (and other punctuation?)
        title = remove_newlines(ee.inner_text)
        title.gsub!(/[\,]$/,'')
        edata = {}
        edata['value'] = title
        add_attributes_to_element_hash(ee, edata)
        @desc_data['unittitle'] << edata
      end
    end 
  end
  
  
  # parse unitdate
  def parse_unitdate(parent_element, level = 'collection')
    unitdates = parent_element.xpath(".//unitdate")
    
    # if no unitdate, use unittitle, which sometimes contains the date without the date being tagged
    if unitdates.length == 0
      unitdates = parent_element.xpath(".//unittitle")
    else
      unitdates.each do |e|
        @desc_data['unitdate'] ||= []
        @desc_data['unitdate'] << basic_element_parse(e)
      end
    end
    
    unitdates.each do |d|
      if d['normal']
        dates_array = d['normal'].split('/')
        date_string = dates_array.join('-')
      else
        date_string = d.inner_text
        # remove 'bulk' if present
        date_string.gsub!(/[(\[\s?)((B|b)ulk\s)(\]\s?)]/,'')
      end
      dates = parse_date_string(date_string)
      if d['type'] == 'bulk'
        @desc_data['date_bulk_start'] = dates[:index_dates].first
        @desc_data['date_bulk_end'] = dates[:index_dates].last
      else
        @desc_data['date_inclusive_start'] = dates[:index_dates].first
        @desc_data['date_inclusive_end'] = dates[:index_dates].last
        if level == 'collection'
          @desc_data['keydate'] = dates[:keydate]
        end
        @desc_data['dates_index'] = dates[:index_dates]
      end
    end
    
  end
  
  
  # parse physdesc
  # EAD_REVISION - structure of physdesc will change
  def parse_physdesc(parent_element, level = 'collection')
    physdesc = parent_element.xpath('.//physdesc')
    if physdesc.length > 0
      physdesc.each do |e|
        if e.element_children.length == 0
          # contents are plain text
          edata = {}
          edata['value'] = clean_inner_text(e.inner_text)
          add_attributes_to_element_hash(e, edata)
          @desc_data['physdesc'] ||= []
          @desc_data['physdesc'] << edata
        else
          e.element_children.each do |ec|
            edata = {}
            key = "physdesc_#{ec.name}"
            edata['value'] = clean_inner_text(ec.inner_text)
            add_attributes_to_element_hash(ec, edata)
            @desc_data[key] ||= []
            @desc_data[key] << edata
            if ec.name == 'extent'
              # catch edge cases
            end
          end
        end
      end
    end 
  end
  
  
  # depricated!
  def parse_did_note(parent_element, level = 'collection')
    notes = parent_element.xpath('./note|.//did/note')
    if notes.length > 0
      notes.each do |n|
        @desc_data['note'] ||= []
        @desc_data['note'] << basic_element_parse(n)
      end
    end
  end
  
  
  def parse_other_descriptive_elements(parent_element, level = 'collection')
    others = ['abstract','materialspec','langmaterial','prefercite']
    others.each do |element_name|
      set = parent_element.xpath(".//#{element_name}")
      if set.length > 0
        set.each do |e|
          @desc_data[element_name] ||= []
          @desc_data[element_name] << basic_element_parse(e)
        end
      end
    end
  end

  
  # parse elements relating to pre-acquisition context
  def parse_context_elements(parent_element)
    @context_data = {}
    origination = parse_origination(parent_element)
    @context_data['origination'] = origination if origination
    elements = ['bioghist','custodhist']
    parse_all_elements_as_html(parent_element, elements, @context_data)
    return !@context_data.blank? ? JSON.generate(@context_data) : nil
  end
  
  
  def parse_origination(parent_element)
    origination = []
    parent_element.xpath('.//origination').each do |o|
      
      subelements = o.xpath("./persname|./corpname|./famname|./name")
      
      # This has proven to not work in some cases! Shit!
      if subelements && subelements.length > 1
        subelements.each do |s|
          edata = {}
          edata['value'] = remove_newlines(s.inner_text)
          edata['type'] = s.name
          edata['role'] = s['role'] if s['role']
          add_attributes_to_element_hash(o, edata)
          origination << edata
        end
      elsif subelements && subelements.length == 1
        edata = {}
        s = subelements.first
        edata['value'] = o.inner_text
        edata['type'] = s.name
        edata['role'] = s['role'] if s['role']
        origination << edata
      else
        edata = {}
        edata['value'] = o.inner_text
        origination << edata
      end
      
    end
    return !origination.blank? ? origination : nil
  end
  
  
  # parse elements related to content and structure
  def parse_content_structure_elements(parent_element)
    elements = ['scopecontent','arrangement']
    @content_structure_data = parse_all_elements_as_html(parent_element, elements)
    return !@content_structure_data.blank? ? JSON.generate(@content_structure_data) : nil
  end
  
  
  # Parse elements related to acquisition & processing
  def parse_acquisition_processing_elements(parent_element)
    elements = ['accruals','acqinfo','separatedmaterial','processinfo','sponsor','appraisal']
    @acquisition_processing_data = parse_all_elements_as_html(parent_element, elements)
    return !@acquisition_processing_data.blank? ? JSON.generate(@acquisition_processing_data) : nil
  end


  # parse elements related to access and use
  def parse_access_use_elements(parent_element, level = 'collection')
    elements = ['container','physloc','accessrestrict','userestrict','legalstatus','phystech','altformavail','originalsloc','otherfindaid']
    @access_use_data = parse_all_elements_as_html(parent_element, elements)
    return !@access_use_data.blank? ? JSON.generate(@access_use_data) : nil
  end
  

  # parse elements related to related material
  def parse_related_material_elements(parent_element, level = 'collection')
    elements = ['relatedmaterial','bibliography']
    @related_material_data = parse_all_elements_as_html(parent_element, elements)
    return !@related_material_data.blank? ? JSON.generate(@related_material_data) : nil
  end
  
  # parse notes that appear as immediate children of archdesc or <c>/<cxx>
  def parse_notes(parent_element)
    elements = parent_element.xpath('.//note|./descgrp/note')
    @notes_data = {}
    elements.each do |e|
      if e.parent.name == 'did'
        note_type = 'did'
      else
        note_type = e['type'] || 'other'
      end
      @notes_data[note_type] ||= []
      @notes_data[note_type] << e.inner_text
    end
    return !@notes_data.blank? ? JSON.generate(@notes_data) : nil
  end
  
end
