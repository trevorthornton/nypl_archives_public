class EadIngest < ActiveRecord::Base
  
  include IngestUtilityMethods
  
  belongs_to :collection
  
  attr_accessible :filename, :collection_id, :update_type
  
  attr_accessor :filepath, :org_unit_id, :active, :identifier_value, :identifier_type, :overwrite
  
  # imports data from EAD - collection must already exist
  def execute
    required_attr = [:filepath, :collection_id]
    missing_attr = []
    required_attr.each { |k| missing_attr << k if !self.send(k) }
    if !missing_attr.empty?
      raise "EadIngest: The following options are required to execute ingest: #{missing_attr.join(',')}."
    else
      # update existing collection, double checking that required attributes are present (this is redundant)
      if !self.collection_id
        raise "EadIngest: You tried to update a collection but a collection ID was not passed to EadIngest."
      elsif !['collection','components','all'].include?(self.update_type)
        raise "EadIngest: Value for @update_type is invalid. Allowed values are: 'collection','components','all'"
      else
        @collection = Collection.find self.collection_id
      end
      
      logger.info "Importing from EAD at #{self.filepath}..."
      
      self.update_type ||= 'all'
      
      @source = open(self.filepath)    
      @doc = Nokogiri::XML(@source)
      # remove namespaces. NOTE: XPath attributes will be ignored
      @doc.remove_namespaces!
      @ead = @doc.root()
      
      if @ead
        @eadheader = @ead.xpath('./eadheader').first
        @frontmatter = @ead.xpath('./frontmatter').first
        @archdesc = @ead.xpath('./archdesc').first
      else
        raise "EadIngest: #{self.filename} does not appear to be a valid EAD document (no <ead> element found)."
      end
      
      if @archdesc
        # EAD_REVISION = <dsc> may be going away, which will make this part a bit harder
        # Probable no-dsc solution is to start with <c> or <c01> that are children of <archdesc>
        @dsc = @archdesc.xpath('.//dsc').first

        # if components are being updated, existing components are stored in an array
        # any existing components not included in the update will be destroyed later
        if ['all','components'].include? self.update_type
          @old_components = []
          Component.find_each(:conditions => "collection_id = #{self.collection_id}") { |c| @old_components << c.id }
        end
        
        # Process collection-level data
        if self.update_type != 'components'
          self.process_collection_data
        end
        
        # Process components if they exist
        if self.update_type != 'collection'
          parse_dsc if @dsc
        end
              
        @collection.post_ingest_updates
        
        # save EadIngest record
        self.save!
      else
        raise "EadIngest: #{self.filename} does not appear to be a valid EAD document (no <archdesc> element found)."
      end
    end
  end  
  
  
  protected
  
  
  def process_collection_data
    # @collection_level_data is archdesc with all components (dsc) removed
    @collection_level_data = @archdesc.clone
    @collection_level_data.xpath('./dsc').each { |dsc| dsc.remove }
    
    # Get date_processed from processinfo if available and add to @collection
    get_date_processed
    
    # generate collection data
    @collection.description.data = parse_description_elements(@collection_level_data, :level => 'collection')
        
    # update collection object attributes
    @collection.add_object_attributes_from_description
    @collection.save
    
    # NOTE: for new collections, description will save with collection, making this next line redundant
    @collection.description.save
    @collection.reload
    
    # extract and save access terms and associations
    process_controlaccess(@collection_level_data, @collection.id, 'Collection')
    @collection
  end
  
  
  def get_date_processed
    @collection_level_data.xpath('.//processinfo').each do |p|
      if p['type'] == 'processing'
        date = p.xpath('.//date').first
        if date
          @collection.date_processed = date.inner_text.to_i
        end
      end
    end
  end
  

  def parse_description_elements(parent_element, options = {})
    response_format = options[:response_format] || 'json'
    @description_data = {}
    parse_unitid(parent_element, options)
    parse_unitdate(parent_element, options) 
    parse_unittitle(parent_element, options)      
    parse_physdesc(parent_element, options)      
    parse_other_did_elements(parent_element, options)
    
    origination = parse_origination(parent_element, options)
    if origination
      @description_data['origination'] = origination
      # origination_to_control_access(origination)
    end
    
    elements = description_elements - descriptive_identity_elements
    elements -= ['origination']
    parse_all_elements_as_html(parent_element, elements, @description_data)
    
    parse_notes(parent_element)
    parse_non_archdesc_elements if options[:level] == 'collection'
    
    compact(@description_data)
    
    if !@description_data.blank?
      return (response_format == 'ruby') ? @description_data : JSON.generate(@description_data)
    else
      nil
    end
  end

  
  def parse_dsc
    @collection ||= Collection.find self.collection_id
    if @dsc

      components_top = get_child_components(@dsc)
      
      @component_count = 0
      sib_seq = 1
      components_top.each do |c|
        process_component(c, {:index => 0, :sib_seq => sib_seq})
        sib_seq += 1
      end
      
      logger.info "Updating #{@component_count.to_s} components of Collection #{@collection.id}"
      
      if !@old_components.empty?
        
        @old_components.each do |cid|
          c = Component.find cid
          c.destroy
          logger.info "Destroying existing component #{cid.to_s} (#{(@old_components.index(cid) + 1).to_s} of #{@old_components.length.to_s})"
        end
      end

    else
      logger.info "EAD file #{self.filename} does not include any components"
    end
  end

  
  # NOTE: this method is recursive
  # element is an EAD component element (<c> or one of <c01> ... <c12>)
  # options[:index] is the 0-based level of the element
  # options[:parent_id] is the database id for the parent component, if applicable
  def process_component(element, options = {})
    
    # @collection_level_data will include all elements contained in this componenet, but none of its subcomponents
    component_level_data = element.clone
    all_components_xpath = ".//c|.//c01|.//c02|.//c03|.//c04|.//c05|.//c06|.//c07|.//c08|.//c09|.//c10|.//c11|.//c12"
    component_level_data.xpath(all_components_xpath).each { |c| c.remove }
    
    @component_count += 1
    component = Component.new
    
    component.collection_id = @collection.id
    component.level_num = options[:index] + 1
    component.level_text = element['level'] || 'file'
    component.parent_id = options[:parent_id]
    component.sib_seq = options[:sib_seq]
    
    # For now, all org_unit_id for components is the same as collection
    # Consider cases where certain components are controlled by different divisions - is there such a thing?
    component.org_unit_id = @collection.org_unit_id
    
    component.description = Description.new(:describable_type => 'Component')
    component.description.data = parse_description_elements(component_level_data, :level => 'component')

    component.add_object_attributes_from_description
    
    update_existing_component = Proc.new do |existing,component|    
      existing.collection_id = component.collection_id
      existing.level_num = component.level_num
      existing.level_text = component.level_text
      existing.parent_id = component.parent_id
      existing.sib_seq = component.sib_seq
      existing.description.data = component.description.data
      existing.add_object_attributes_from_description
    end
    
    # check for existing component based on identifier_value/identifier_type    
    
    if component.identifier_value && component.identifier_type
      existing_component = Component.where(
        :identifier_value => component.identifier_value,
        :identifier_type => component.identifier_type).first
    end
    
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
    
    # Note association params are included in returned hash, then assigned to the association below
    process_terms = lambda do |element_set|
      access_terms = {}
      element_set.each do |e|
        term = remove_newlines(e.inner_text)
        if !term.blank?
          access_terms[term] ||= {}
          if e['source']
            access_terms[term][:authority] = e['source'] == 'lcnaf' ? 'naf' : e['source']
          end
        
          if e['authfilenumber']
            if e['authfilenumber'].match(/^http:/)
              access_terms[term][:value_uri] = e['authfilenumber']
            else
              access_terms[term][:authority_record_id] = e['authfilenumber']
            end
          end
        
          if e['role']
            access_terms[term][:role] = e['role']
            if e['role'].match(/[Ss]ubject/)
              access_terms[term][:name_subject] = true
            end
          end        
        
          case e.name
          when 'subject'
            access_terms[term][:term_type] = 'topic'
          when 'occupation'
            access_terms[term][:term_type] = 'topic'
            access_terms[term][:function] = 'occupation'
          else
            access_terms[term][:term_type] = e.name
          end

          access_terms[term][:term_original] = term
        
          if name_elements.include?(e.name)
            # if name is in <origination> add function to association
            e.ancestors.each do |a|
              if a.name == 'origination'
                access_terms[term][:function] = 'origination'
                break
              end
            end
          end
        end
      end
      
      return access_terms
    end
    
    
    save_terms_and_associations = Proc.new do |access_terms, controlaccess|
      access_terms.each do |k,v|
        # v is a hash of params
        
        # extract relation params from term hash
        association_params = {}
        
        if v[:role]
          association_params[:role] = v[:role]
          v.delete(:role)
        end
        
        if v[:function]
          association_params[:function] = v[:function]
          v.delete(:function)
        end
        
        if v[:name_subject]
          association_params[:name_subject] = v[:name_subject]
          v.delete(:name_subject)
        end
        
        association_params[:controlaccess] = controlaccess ? true : false
        
        existing_term = AccessTerm.where(v).first
        
        if !existing_term
          t = AccessTerm.new(v)
          puts t.inspect
          t.save
        else
          t = existing_term
        end
        
        association_params[:access_term_id] = t.id
        association_params[:describable_type] = describable_type
        association_params[:describable_id] = describable_id

        AccessTermAssociation.create(association_params)
        
      end
    end
    
    controlaccess = parent_element.xpath('.//controlaccess').first
    access_elements_xpath = './/'
    access_elements_xpath += access_elements.join('|.//')
    
    controlaccess_element_set = controlaccess ? controlaccess.xpath(access_elements_xpath) : nil
    # other_terms_element_set = all terms in parent not included in controlaccess
    # (controlaccess elements are removed below)
    other_terms_element_set = parent_element.xpath(access_elements_xpath)
    
    # Delete existing access_term_associations before creating new ones
    AccessTermAssociation.where(:describable_type => describable_type,
      :describable_id => describable_id).each do |a|
        a.destroy
    end
    
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
  
 
  # parse unitid
  def parse_unitid(parent_element, options = {})
    unitid = parent_element.xpath('.//unitid')
    
    if unitid.length > 0
      @description_data['unitid'] = []
      unitid.each do |e|
        if !e.blank?
          edata = {}
          if e.inner_text.match(/(MssCol)|(msscol)/)
            edata['value'] = e.inner_text.gsub(/[^\d]/,'')
            edata['type'] = 'local_mss'
          else
            edata['value'] = remove_newlines(e.inner_text)
            edata['type'] = e['type']
          end
          add_attributes_to_element_hash(e, edata)
          @description_data['unitid'] << edata
        
          if (edata['type'] == 'local_mss') && (options[:level] == 'collection')
            call_number_unitid = { 'value' => "MssCol #{edata['value']}", 'type' => 'local_call' }
            if !@description_data['unitid'].include?(call_number_unitid)
              @description_data['unitid'] << call_number_unitid
            end
          end
        end
      end
      
      @description_data['unitid'].uniq!
      
    end
  end
  
  
  # parse unittitle
  def parse_unittitle(parent_element, options = {})
    unittitle = parent_element.xpath('.//unittitle')
    if unittitle.length > 0
      @description_data['unittitle'] = []
      unittitle.each do |e|
        # Clone element because we have to strip out the nested unitdate, which we might need later
        ee = e.clone
        
        if !ee.blank?
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
          @description_data['unittitle'] << edata
        end
      end
    end 
  end
  
  
  # parse unitdate
  def parse_unitdate(parent_element, options = {})
    level = options[:level] ? options[:level] : 'collection'
    unitdates = parent_element.xpath(".//unitdate")
    # if no unitdate, use unittitle, which sometimes contains the date without the date being tagged
    if unitdates.length == 0
      unitdates = parent_element.xpath(".//unittitle")
    else
      unitdates.each do |e|
        if !e.blank?
          @description_data['unitdate'] ||= []
          edata = {}
          add_attributes_to_element_hash(e, edata)
          # get value, remove 'bulk' if present
          edata['value'] = clean_date_string(e.inner_text)
          @description_data['unitdate'] << edata
        end
      end
    end
    if @description_data['unitdate']
      @description_data['unitdate'].each do |d|
        date_values = generate_extended_date_values(d,level)
        date_values.each do |k,v|
          @description_data[k] ||= v
        end
      end
    end
  end
  
  
  # parse physdesc
  # EAD_REVISION - structure of physdesc will change
  def parse_physdesc(parent_element, options = {})
    physdesc = parent_element.xpath('.//physdesc')
    if physdesc.length > 0
      physdesc.each do |e|
        if !e.blank?
          if (e.element_children.length == 0)
            # contents are plain text
            edata = {}
            edata['format'] = 'simple'
            edata['value'] = clean_inner_text(e.inner_text)
            add_attributes_to_element_hash(e, edata)
            (@description_data['physdesc'] ||= []) << edata
          else
            edata = {}
            edata['format'] = 'structured'
            edata['physdesc_components'] ||= []
            e.element_children.each do |ec|
              physdesc_component = { 'name' => ec.name, 'value' => clean_inner_text(ec.inner_text) }
              if !physdesc_component['value'].blank?
                add_attributes_to_element_hash(ec, physdesc_component)
                edata['physdesc_components'] << physdesc_component
              end
            end
            if !edata['physdesc_components'].empty?
              (@description_data['physdesc'] ||= []) << edata
            end
          end
        end
      end
    end 
  end
  

  def parse_other_did_elements(parent_element, options = {})
    elements = descriptive_identity_elements - ['unitid','unittitle','unitdate','physdesc']
    elements.each do |element_name|
      set = parent_element.xpath(".//#{element_name}")
      if set.length > 0
        set.each do |e|
          if !e.blank?
            @description_data[element_name] ||= []
            @description_data[element_name] << basic_element_parse(e)
          end
        end
      end
    end
  end
  
  
  def parse_origination(parent_element, options = {})
    origination = []
    parent_element.xpath('.//origination').each do |o|
      if !o.blank?
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
          edata['value'] = remove_newlines(o.inner_text)
          edata['type'] = s.name
          edata['role'] = s['role'] if s['role']
          origination << edata
        else
          edata = {}
          edata['value'] = remove_newlines(o.inner_text)
          origination << edata
        end
      end
    end
    return !origination.blank? ? origination : nil
  end
  
  
  def parse_notes(parent_element, options = {})
    source = parent_element.clone
    # remove all previously parsed elements from source
    description_elements.each do |e|
      source.xpath(".//#{e}").each { |n| source.delete(n) }
    end
    note_elements = source.xpath('.//note')
    note_elements.each do |e|
      if !e.blank?
        if e.parent.name == 'did'
          note_type = 'did'
        else
          note_type = e['type'] || nil
        end
        note = {}
        note['type'] = note_type if note_type
        note['value'] = remove_newlines(e.inner_text) if e.inner_text
        (@description_data['note'] ||= []) << note if !note.blank?
      end
    end
  end
  
  
  # A few elements that need to be imported are not in archdesc
  def parse_non_archdesc_elements
    
    # Sponsor (found in eadheader and/or frontmatter but not in archdesc)
    sponsor = []    
    header_sponsor = @eadheader ? @eadheader.xpath('.//sponsor').to_a : []
    frontmatter_sponsor = @frontmatter ? @frontmatter.xpath('.//sponsor').to_a : []
    sponsor_elements = header_sponsor + frontmatter_sponsor
    sponsor_elements.each do |s|
      if s.inner_text && !sponsor.include?(s.inner_text)
        sponsor << s.inner_text
      end
    end
    
    if !sponsor.blank?
      @description_data['sponsor'] ||= []
      sponsor.each { |s| @description_data['sponsor'] << { 'value' => s } }
    end
    
    # Author from eadheader/filedesc/titlestmt OR frontmatter/titlepage (prefer eadheader version)
    eadheader_author = @eadheader ? @eadheader.xpath('./filedesc/titlestmt/author').to_a : []
    frontmatter_author = @frontmatter ? @frontmatter.xpath('./titlepage/author').to_a : []
    author = !eadheader_author.blank? ? eadheader_author : frontmatter_author
    
    author.uniq!
    author.each do |a|
      value = a.inner_text
      remove_newlines(value)
      if !value.match(/\.\s?$/)
        value += '.'
      end
      value = "<p>#{value}</p>"
      (@description_data['processinfo'] ||= []) << { 'value' => value } if value
    end
    
  end

  # utility methods
  
  def get_child_components(element,index=0)
    numbered_components = ['c01','c02','c03','c04','c05','c06','c07','c08','c09','c10','c11','c12']
    xpath = "./c|./#{numbered_components[index]}"
    components = element.xpath(xpath)
  end
  
  
  def parse_all_elements_as_html(parent_element, elements, data={})
    elements.each do |element_name|
      all_elements = parent_element.xpath(".//#{element_name}")
      nested_elements = parent_element.xpath(".//#{element_name}/#{element_name}")
      element_set = all_elements - nested_elements
      if element_set.length > 0
        element_set.each do |e|
          data[element_name] ||= []
          data[element_name] << basic_element_parse(e)
        end
      end
    end
    return data
  end
  
  
  def basic_element_parse(element, html=true)
    edata = {}
    add_attributes_to_element_hash(element, edata)
    edata['value'] = ead_element_value_to_html(element)
    edata
  end
  
  
  def ead_element_value_to_html(element, level = 0)
    
    common_elements = ['p','blockquote','div']
    block_elements = ['note','address','bioghist','scopecontent','arrangement']
    inline_elements = ['abbr','addressline','archref','bibref','bibseries','date',
      'edition', 'emph','expan','imprint','num','subarea','persname','famname','corpname',
      'genreform','geogname','name','subject','title','occupation']
    list_elements = ['chronlist','list']
    list_content_elements = ['chronitem','eventgrp','date','event','item','defitem']
    head_elements = ['head','head01','head02']
    table_elements = ['table','tgroup','colspec','tbody','thead','row']
    
    
    special_elements = list_elements.concat(head_elements).concat(table_elements)
    
    # @append_data can be used to store data to be added to the end of the element value, esp. footnotes
    @append_data ||= {}
    
    element.element_children.each do |c|
      if c.inner_text.blank?
        c.remove
      else
        if common_elements.include?(c.name)
          # leave as is
        
        
        # Look for footnotes
        # Footnotes will be appended to the end of the top-level element's content
        # Multiple paragraphs in footnotes will be combined (in most cases there will only be one)
        elsif (c.name == 'note') && (c['actuate'] == 'onrequest')
          @append_data[:footnotes] ||= []
          footnote_index = @append_data[:footnotes].length + 1
          footnote = { :index => footnote_index.to_s,
            :id => "footnote_#{DateTime.now.strftime('%M%S%6N')}", :value => c.inner_html }
          footnote[:value].gsub!(/\<p\>/,'<span class="note_contents">')
          footnote[:value].gsub!(/\<\/p\>/,'</span>')
          @append_data[:footnotes] << footnote
          c.replace("[<a href='##{footnote[:id]}' class='footnote-link'>#{footnote_index.to_s}</a>]")
         
          
        elsif block_elements.include?(c.name)
          c.attributes.each { |k,v| c.remove_attribute(k) }
          c['class'] = c.name
          c.name = 'div'
        
        # catch emph and convert to em
        elsif c.name == 'emph'
          c.name = 'em'
        
        elsif inline_elements.include?(c.name)
          c.attributes.each { |k,v| c.remove_attribute(k) }
          c['class'] = c.name
          c.name = 'span'
        
        elsif head_elements.include?(c.name)
          if common_head_values.include?(c.inner_text.strip.gsub(/[^\w\d]*$/,''))
            c.remove
          else
            c.attributes.each { |k,v| c.remove_attribute(k) }
            c['class'] = 'head'
            c.name = 'div'
          end
          
        elsif list_elements.include?(c.name)
          type = c['type']
          c.attributes.each { |k,v| c.remove_attribute(k) }
          c['class'] = c.name
          c.name = type == 'ordered' ? 'ol' : 'ul'
        
        elsif list_content_elements.include?(c.name)
          c.attributes.each { |k,v| c.remove_attribute(k) }
          case c.name
          when 'chronitem','item','defitem'
            c['class'] = c.name if c.name == 'chronitem'
            c.name = 'li'
          when 'date','event'
            c['class'] = c.name
            c.name = 'span'
          when 'eventgrp'
            c['class'] = c.name
            c.name = 'div'
          end
        
        elsif table_elements.include?(c.name)
          # skip for now
        else
          c.replace(c.inner_text)
        end
      end
      ead_element_value_to_html(c, level + 1)
    end

    if level == 0
      html = element.inner_html
      
      if @append_data[:footnotes]
        html += '<div class="footnotes">'
        @append_data[:footnotes].each do |f|
          html += "<div id='#{f[:id]}' class='note'>#{f[:index]} - #{f[:value]}</div>"
        end
        html += '</div>'
      end
      # unset @append_data after processing it
      @append_data = nil
      remove_newlines(html)
      remove_blank_paragraphs(html)
    else
      remove_newlines(element.inner_html)
      remove_blank_paragraphs(element.inner_html)
      element
    end
    
  end
  
  
  def skip_attributes
    ['encodinganalog','label']
  end
  
  
  def common_head_values
    ['Contact Information', 'Descriptive Summary', 'Administrative Information',
    'Source', 'Custodial History', 'Access', 'Processing Information', 'Preferred Citation','Index Terms','Names',
    'Subjects','Places','Document types','Occupations','Creator History','Scope and content note','Organization',
    'Related Collections','Series Descriptions and Container List','Organizations',
    'Historical note','Scope and Content Note','Restrictions on Use','Access','Publication Rights',
    'Preferred Citation','Custodial History','Processing Information','Biographical Note','Scope and Content Note',
    'Organization and Arrangement','Series Description and Container Listing','Subjects','Personal Names','Document Types',
    'Administration Information','Biography','Container List','Contact Information','Access','Publication Rights','Preferred Citation',
    'Custodial History','Series Description','Container Listing','Separated Materials','Organizations','Subjects',
    'Document Types','Titles','Biographical note','Series Descriptions','Publication Rights',
    'Alternate Format','Related Material','Biographical Note','Item Descriptions','Places',
    'Occupations','Series Descriptions/Container List','Contents List','Historical Note','Scope and Content',
    'Series Description/Container Listing','Scope And Content','Biographical History','Series Description/Container List',
    'Separated Material','Related Materials','Collection Listing','Container List and Series Descriptions',
    'Restrictions on use','Titles','Organization Note','Access Restrictions','Index Terms','Persons',
    'Scope and Contents Note','Arrangement Note','User Restrictions','Biographical Sketch','Arrangement',
    'Contact Information','Organization and Arrangement','Series Descriptions and Container Listing','Folder List','Organizational History','Provenance',
    'Administrative History','Bibliography','BIOGRAPHY','SCOPE AND CONTENT','CONTAINER LIST','Container List and Series Description','Acquisition Information',
    'Contents','Separated material','Series Description and Container Listing',
    'History','Historical Sketch','Forms and Genres','Container Listing and Series Descriptions','Scope and Contents',
    'Index terms','Names','Scope and content','Organization of collection',
    'Historical Statement','Organization of Collection','Series Descriptions and Container Lists','Container list','Organization and Arrangement',
    'Events','Access Restriction','Date','Event','Chronological List of Events',
    'Organization and Arranagement','Alternate Formats','Use Restrictions','Series Description','Collection List',
    'ACQUISITION INFORMATION','ORGANIZATION AND arrangement','SCOPE AND CONTENT NOTE','SERIES DESCRIPTIONS/CONTAINER LIST','Description of Series/Container List',
    'Contents','Separated materials','BIOGRAPHICAL SKETCH','SERIES DESCRIPTIONS','FOLDER LIST',
    'SEPARATION LIST ','Contents','Series','Biography and Historical Note','Biographical Note',
    'Scope and Content Note','Series Description','Container Listing / Series Description','ACCESS','CHRONOLOGY',
    'Scope and Contents / Organization Note','Administration Information ','Copyright','Biography','Organization',
    'Series Descriptions/Container List','Summary','Series Description/ Container List','Alternative Format','Biographical Notes',
    'Complementary Material','Publication rights','Organizational Note','Related names and works','Series Description / Container Listing',
    'Organization And Arrangement','Container Listing','CONTAINER LIST','SEPARATION LIST','Series Descriptions and Container Listings',
    'Scope and Contents ; Organization','Separated Material','ITEM LIST','Alternate format','Preferred citation','Biographical information',
    'Separated Materials','HISTORICAL NOTE','ORGANIZATION AND ARRANGEMENT','Container List/Series Descriptions','Preferred','Citation',
    'Separated','Material','Legal Status','Arrangement','Container List (Selected index)','History Note',
    'Series Description and Container List','Separated Materials','Container Listing / Series Descriptions','Organization and arrangement','Biographies']
  end
  
  
end
