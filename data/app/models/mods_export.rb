class ModsExport
  
  require 'nokogiri'
  require 'json'
  include IngestUtilityMethods
  
  @@template_path = "#{Rails.root}/lib/xml_templates/mods_template.xml"
  
  def initialize(options = {})
    @doc = Nokogiri::XML(open(@@template_path))
    @mods = @doc.root
    if options[:describable_type] && options[:describable_id]
      case options[:describable_type]
      when 'Collection'
        @record = Collection.find options[:describable_id]
      when 'Component'
        @record = Component.find options[:describable_id]
      end
    end
  end
  
  
  def execute(options={})
    if !@record || !@record.description
      puts "No record = no MODS"
      return false
    else
      @data = @record.description_data
      
      @access_term_data = @record.access_term_data
      add_mods_titleInfo
      add_mods_name
      add_mods_typeOfResource
      add_mods_originInfo
      add_mods_language
      add_mods_physicalDescription
      add_mods_abstract
      add_mods_subject
      add_mods_note
      add_mods_identifier
      add_mods_location
      add_mods_accesscondition
      if options[:filepath]
        export_file = File.new(@filepath,'w')
        export_file << @doc.to_s
        export_file.close
        return true
      else
        @doc.to_s
      end
    end
  end
  
  
  private
  
  def add_mods_titleInfo
    titleInfo = Nokogiri::XML::Node.new('titleInfo',@doc)
    title = Nokogiri::XML::Node.new('title',@doc)
    if @record.title
      title << @record.title
    elsif @record.date_statement
      title << @record.date_statement
    end
    titleInfo << title
    titleInfo['supplied'] = "yes"
    @mods << titleInfo
  end
  
  
  def add_mods_originInfo
    originInfo_data = {}

    mods_dates = get_mods_dates
    if !mods_dates.blank?
      originInfo_data['dateCreated'] = mods_dates
    end
    
    origination_place = @record.origination_place
    if origination_place
      originInfo_data['place'] = origination_place
    end
    
    if !originInfo_data.blank?
      originInfo = Nokogiri::XML::Node.new('originInfo',@doc)
      if originInfo_data['dateCreated']
        originInfo_data['dateCreated'].each do |d|
          dateCreated = Nokogiri::XML::Node.new('dateCreated',@doc)
          dateCreated << (d.delete('value') || '')
          d.each { |k,v| dateCreated[k] = v }
          originInfo << dateCreated
        end
      end
      if originInfo_data['place']
        originInfo_data['place'].each do |p|
          place = Nokogiri::XML::Node.new('place',@doc)
          placeTerm = Nokogiri::XML::Node.new('placeTerm',@doc)
          placeTerm << p[:term]
          add_authority_attributes_to_element(placeTerm,p)
          place << placeTerm
          originInfo << place
        end
      end
      @mods << originInfo
    end
  end
  
  
  def get_mods_dates
    dates = {}
    # normalized unitdate
    if @data['unitdate']
      @data['unitdate'].each do |ud|
        
        
        
        # only check the first date that is not a bulk date
        if ud['type'] != 'bulk'
          dates[:normal] = ud['normal'] if ud['normal']
          dates[:text] = ud['value'] if ud['value']
          break
        end
      end
    end
    
    puts "***"
    puts dates.inspect
    
    if dates[:normal]
      if dates[:normal].match(/^[^\/]*\/[^\/]$/)
        dates[:normal_range] = dates[:normal].split('/')
      end
    end
    
    if !dates[:normal_range] && (@data['date_inclusive_start'] || @data['date_inclusive_end'])
      dates[:range] ||= []
      dates[:range][0] = @data['date_inclusive_start'].to_s || ''
      dates[:range][1] = @data['date_inclusive_end'].to_s || ''
    end
    
    if dates[:range]
      if dates[:range][0] == dates[:range][1]
        dates[:text] = dates[:range][0] if !dates[:text]
        dates.delete(:range)
      elsif dates[:range].join('-') == dates[:text]
        dates.delete(:text)
      end
    end
    
    # order of precidence: (normal_range || normal), range || text
    mods_dates = []
    if dates[:normal_range]
      if !dates[:normal_range][0].blank?
        mods_dates << { 'value' => dates[:normal_range][0], 'point' => 'start', 'encoding' => 'iso8601' }
      end
      if !dates[:normal_range][1].blank?
        mods_dates << { 'value' => dates[:normal_range][1], 'point' => 'end', 'encoding' => 'iso8601' }
      end
    elsif dates[:normal]
      mods_dates << { 'value' => dates[:normal], 'encoding' => 'iso8601' }
    elsif dates[:range]
      if !dates[:range][0].blank?
        mods_dates << { 'value' => dates[:range][0], 'point' => 'start', 'encoding' => 'iso8601' }
      end
      if !dates[:range][1].blank?
        mods_dates << { 'value' => dates[:range][1], 'point' => 'end', 'encoding' => 'iso8601' }
      end
    elsif dates[:text]
      mods_dates << { 'value' => dates[:text] }
    end

    mods_dates
  end
  
  
  def add_mods_name
    names = @access_term_data['name']
    puts names.inspect
    
    if !names.blank?
      names.each do |n|
        
        if !n[:role] && n[:function] == 'origination'
          n[:role] = 'Creator'
        end
        
        if n[:role] != 'Subject'
          name = Nokogiri::XML::Node.new('name',@doc)
          
          add_authority_attributes_to_element(name,n)
          name['type'] = mods_name_type(n[:type]) if mods_name_type(n[:type])  
          
          namePart = Nokogiri::XML::Node.new('namePart',@doc)
          namePart << n[:term]
          name << namePart
          
          if n[:role] && (!['Subject','Heading'].include?(n[:role]))
            role = Nokogiri::XML::Node.new('role',@doc)
            role_text = Nokogiri::XML::Node.new('roleTerm',@doc)
                        
            role_data = marc_relators_on_label(n[:role])
            if role_data
              role_text['authority'] = 'marcrelator'
              role_text['valueURI'] = role_data[:uri]
              role_code = role_text.clone
              role_code['type'] = 'code'
              role_code << role_data[:code]
              role << role_code
            end
            role_text['type'] = 'text'
            role_text << n[:role]
            role << role_text
            name << role
          end
          # n.each { |k,v| name[k] = v if v}
          if !name.content.blank?
            @mods << name
          end
        end
        
      end
    end

  end
  
  
  def add_mods_subject
    names = @access_term_data.delete('name') || []
    
    add_subject_to_mods = Proc.new do |subject_subelement|
      if !subject_subelement.content.blank?
        subject = Nokogiri::XML::Node.new('subject',@doc)
        subject << subject_subelement
        @mods << subject
      end
    end
    
    names.each do |n|
      if n[:role] == 'Subject'
        name = Nokogiri::XML::Node.new('name',@doc)
        add_authority_attributes_to_element(name,n)
        name['type'] = mods_name_type(n[:type]) if mods_name_type(n[:type])
        namePart = Nokogiri::XML::Node.new('namePart',@doc)
        namePart << n[:term]
        name << namePart
        add_subject_to_mods.call(name)
      end
    end
    
    @access_term_data.each do |k,terms|
      if k == 'title'
        terms.each do |t|
          titleInfo = Nokogiri::XML::Node.new('titleInfo',@doc)
          title = Nokogiri::XML::Node.new('title',@doc)
          title << t[:term]
          if !title.content.blank?
            titleInfo << title
            add_subject_to_mods.call(titleInfo)
          end
        end
      else
        terms.each do |t|
          if t[:term]
            element_name = mods_subject_subelement(k)
            element = Nokogiri::XML::Node.new(element_name,@doc)
            add_authority_attributes_to_element(element,t)
            element << t[:term]
            add_subject_to_mods.call(element)
          end
        end
      end
    end
  end
  
  
  
  def add_mods_physicalDescription
    physicalDescription = Nokogiri::XML::Node.new('physicalDescription',@doc)
    
    if @record.extent_statement
      extent = Nokogiri::XML::Node.new('extent', @doc)
      extent << @record.extent_statement
      physicalDescription << extent
    end
    
    if @data['physdesc']
      @data['physdesc'].each do |p|
        if (p['format'] == 'simple') && !p['supress_display'] && !p['value'].blank?
          note = Nokogiri::XML::Node.new('note',@doc)
          note << p['value']
          physicalDescription << note
        end
      end
    end

    if !physicalDescription.content.blank?
      @mods << physicalDescription
    end
    
  end
  
  
  def add_mods_abstract
    if @data['abstract']
      @data['abstract'].each do |a|
        abstract = Nokogiri::XML::Node.new('abstract',@doc)
        if a['value']
          abstract << convert_paragraphs(a['value'])
        end
        @mods << abstract
      end
    end
  end
  
  
  def add_mods_note
    notes = []
    
    # bioghist
    if @data['bioghist']
      @data['bioghist'].each do |b|
        
        note = {}
        if b['value']
          note['value'] = convert_paragraphs(b['value'])
          note['type'] = 'biographical/historical'
        end
        notes << note
      end
    end
    
    # scopecontent
    if @data['scopecontent']
      @data['scopecontent'].each do |s|
        if (s['type'] != 'arrangement') && !s['supress_display']
          note = {}
          if s['value']
            note['value'] = convert_paragraphs(s['value'])
            note['type'] = 'content'
          end
          notes << note
        end
      end
    end
    
    # EAD note
    if @data['note']
      @data['note'].each do |n|
        note = {}
        if n['value']
          note['value'] = convert_paragraphs(n['value'])
          note['type'] = n['type'] if n['type']
        end
        notes << note
      end
    end

    # compact(notes)
    
    notes.each do |n|
      note = Nokogiri::XML::Node.new('note',@doc)
      n.each do |k,v|
        if k == 'value' && !v.blank?
          note << v
        else
          note[k] = v
        end
      end
      @mods << note
    end
  end
  
  
  def add_mods_identifier
    identifiers = []
    
    bnumber = @record.class == Collection ? @record.bnumber : nil
    
    if @data['unitid']
      @data['unitid'].each do |i|
        if i['type'] == 'local_bnumber'
          bnumber ||= i['value']
        elsif i['type'] != 'local_call'
          identifiers << i
        end
      end
    end
    
    if bnumber
      identifiers << { 'value' => bnumber, 'type' => 'local_bnumber' }
    end
    
    identifiers.each do |i|
      identifier = Nokogiri::XML::Node.new('identifier',@doc)
      if i['value']
        identifier << i['value']
        identifier['type'] = i['type'] if i['type']
        @mods << identifier
      end
    end
  end
  
  
  def add_mods_accesscondition
    ['accessrestrict','userestrict'].each do |k|
      if @data[k]
        @data[k].each do |r|
          if r['value']
            accesscondition = Nokogiri::XML::Node.new('accessCondition',@doc)
            accesscondition << convert_paragraphs(r['value'])
            @mods << accesscondition
          end
        end
      end
    end
  end
  
  def add_mods_location
    if @record.class == Collection
      call_number = @record.call_number || @record.call_number_from_description
    else
      call_number = nil
    end
    
    if call_number
      location = Nokogiri::XML::Node.new('location',@doc)
      shelfLocator = Nokogiri::XML::Node.new('shelfLocator',@doc)
      shelfLocator << call_number
      location << shelfLocator
      @mods << location
    end
  end
  
  
  def add_mods_typeOfResource
    if @record.class == Collection
      type_of_resource = Nokogiri::XML::Node.new('typeOfResource',@doc)
      type_of_resource << "text"
      type_of_resource['collection'] = 'yes'
      @mods << type_of_resource
    elsif @record.class == Component
      if !@record.resource_type.blank?
        # values for resource_type correspond to MODS typeOfResource allowed values
        # but sometimes they have '/manuscript' appended to the end, which triggers incluision of @manuscript="yes" in MODS element
        type_of_resource = Nokogiri::XML::Node.new('typeOfResource',@doc)
        type_of_resource << @record.resource_type.split('/')[0]
        type_of_resource['usage'] = 'primary'
        if @record.resource_type.split('/')[1] == 'manuscript'
          type_of_resource['manuscript'] = 'yes'
        end
        @mods << type_of_resource
      end
    end
  end
  
  
  def add_mods_language
    if @data['langmaterial_code']
      @data['langmaterial_code'].each do |c|
        language = Nokogiri::XML::Node.new('language',@doc)
        language_term_code = Nokogiri::XML::Node.new('languageTerm',@doc)
        language_term_code['type'] = 'code'
        language_term_code['authority'] = 'iso639-2b'
        language_term_code << c
        language << language_term_code
        language_name = language_string_to_code.invert[c]
        if language_name
          language_term_text = Nokogiri::XML::Node.new('languageTerm',@doc)
          language_term_text['type'] = 'text'
          language_term_text << language_name
          language << language_term_text
        end
        @mods << language
      end
    end
  end
  

  def convert_paragraphs(text)
    if text.match('<p>')
      text.strip!
      text.gsub!(/\<\/p\>$/,"")
      text.gsub!(/\<\/p\>/,"\n\n")
      text.gsub!(/\<p\>/,'')
    end
    
    # remove spans
    if text.match('</span>')
      text.gsub!(/\<span(\sclass\=\"[^\"]*\")?\s?\>/,"")
      text.gsub!(/\<\/span\>/,"")
    end
    text
  end
  
  
  def add_authority_attributes_to_element(element,term_hash)
    if term_hash[:source]
      element['authority'] = term_hash[:source]
    end
    
    if term_hash[:value_uri]
      element['valueURI'] = term_hash[:value_uri]
    end
  end
  
  def mods_name_type(type)
    types = {
      'persname' => 'personal',
      'corpname' => 'corporate',
      'famname' => 'family',
    }
    types[type]
  end
  
  def mods_subject_subelement(ead_element_name)
    subelement_names = {
      'genreform' => 'genre',
      'geogname' => 'geographic',
      'subject' => 'topic',
      'title' => 'title',
      'occupation' => 'occupation'
    }
    subelement_names[ead_element_name]
  end
  
end