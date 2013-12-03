module CatalogImportUtilityMethods
  
  include IngestUtilityMethods
  include NyplCatalogExtractor
  
  
  # NOTE: See access_terms_from_marc for more - 1xx field values are also stored as access terms
  def origination_from_marc(tag,field)
    # 100 Main entry--personal name -> <origination><persname> / <origination><famname>
    # 110 Main entry--corporate name -> <origination><corpname>
    # 111 Main entry--meeting name -> <origination><corpname>
    origination = { 'value' => concatenate_subfields(tag,field) }
    origination['type'] = access_term_type(tag,field)
    # origination.each { |k,v| strip_stop(v) }
    (@description[:data]['origination'] ||= []) << origination
  end
  
  
  def unittitle_unitdate_from_marc(tag,field)
    case tag
    when '130'
      # 130 Main entry--uniform title -> <unittitle>
      unittitle = { 'value' => concatenate_subfields(tag,field) }
      (@description[:data]['unittitle'] ||= []) << unittitle
    when '245'
      # 245 Title statement	-> <unittitle>
      unittitle = { 'value' => concatenate_subfields(tag,field) }
      (@description[:data]['unittitle'] ||= []) << unittitle
      # 245$f Title statement/inclusive dates	-> <unitdate type="inclusive">
      if subfield_value(field,'f')
        unitdate = { 'value' => subfield_value(field,'f'), 'type' => 'inclusive' }
        (@description[:data]['unitdate'] ||= []) << unitdate
      end
      # 245$g Title statement/bulk dates -> <unitdate type="bulk">
      if subfield_value(field,'g')
        unitdate = { 'value' => subfield_value(field,'g'), 'type' => 'bulk' }
        clean_date_string(unitdate['value'])
        (@description[:data]['unitdate'] ||= []) << unitdate
      end
    when '260'
      # 260$c Date -> <unitdate>
      if subfield_value(field,'c') 
        unitdate = { 'value' => subfield_value(field,'c') }
        clean_date_string(unitdate['value'])
        (@description[:data]['unitdate'] ||= []) << unitdate
      end
    end
  end
  
  
  def materialspec_from_marc(tag,field)
    # 254 Musical presentation statement -> <materialspec>
    # 255 Cartographic mathematical data -> <materialspec>
    # 256 Computer file characteristics -> <materialspec>
    case tag
    when '254'
      materialspec = { 'type' => 'musical presentation statement', 'value' => subfield_value(field,'a') }
      (@description[:data]['materialspec'] ||= []) << materialspec
    when '255'
      field[:subfields].each do |s|
        materialspec = nil
        case s.keys.first
        when 'a'
          materialspec = { 'type' => 'scale', 'value' => subfield_value(field,'a') }
        when 'b'
          materialspec = { 'type' => 'projection', 'value' => subfield_value(field,'b') }
        when 'c'
          materialspec = { 'type' => 'coordinates', 'value' => subfield_value(field,'c') }
        when 'd'
          materialspec = { 'type' => 'zone', 'value' => subfield_value(field,'d') }
        when 'e'
          materialspec = { 'type' => 'equinox', 'value' => subfield_value(field,'e') }
        when 'f'
          materialspec = { 'type' => 'outer g-ring coordinate pairs', 'value' => subfield_value(field,'f') }
        when 'g'
          materialspec = { 'type' => 'exclusion g-ring coordinate pairs', 'value' => subfield_value(field,'g') }
        end
        (@description[:data]['materialspec'] ||= []) << materialspec if materialspec
      end
    when '256'
      materialspec = { 'type' => 'file characteristics', 'value' => subfield_value(field,'a') }
      (@description[:data]['materialspec'] ||= []) << materialspec
    end
  end


  def physdesc_from_marc(tag,field)
    # 300 Physical description -> <physdesc> and subelements <extent>, <dimensions>, <genreform>, <physfacet>
    subfields = field[:subfields]
    subfield_indicators = subfields_present(field)        
    cleanup_300_subfields(subfields,subfield_indicators)
    
    physdesc = { 'format' => 'structured', 'physdesc_components' => [] }
    
    subfield_indicators.each_index do |i|
      case subfield_indicators[i]
      when 'a'
        physdesc_extent = { 'name' => 'extent' }
        extent = subfields[i]['a']
        # look for $f following $a and append it
        if subfield_indicators[i + 1] == 'f'
          extent += " " + subfields[i + 1]['f']
          # look for $g following $f and append it
          if subfield_indicators[i + 2] == 'g'
            extent += ", " + subfields[i + 1]['f'].gsub(/[\(\)]/,'')
          end
        end
        physdesc_extent['value'] = strip_stop(extent)
        physdesc['physdesc_components'] << physdesc_extent
        
      when 'c'
        physdesc_dimensions = { 'name' => 'dimensions' }
        dimensions = subfields[i]['c']
        physdesc_dimensions['value'] = strip_stop(dimensions)
        physdesc['physdesc_components'] << physdesc_dimensions
      
      when 'b'
        physdesc_physfacet = { 'name' => 'physfacet' }
        physfacet = subfields[i]['b']
        physdesc_physfacet['value'] = strip_stop(physfacet)
        physdesc['physdesc_components'] << physdesc_physfacet
      
      when 'g'
        if i != 0
          if !physdesc['physdesc_components'].blank?
            (@description[:data]['physdesc'] ||= []) << physdesc if physdesc
          end
          physdesc = { 'format' => 'structured', 'physdesc_components' => [] }
        end
        physdesc_label = subfields[i]['g']
        physdesc['label'] = physdesc_label
      end
    end
    if !physdesc['physdesc_components'].blank?
      (@description[:data]['physdesc'] ||= []) << physdesc if physdesc
    end
  end
  
  
  # helper function for physdesc_from_marc()
  def cleanup_300_subfields(subfields,subfield_indicators)
    # if $e, get it's index, then find the element right before it and remove any trailing '+'
    #   and remove any '&' at the beginning of $e (for non-AACR2 records formulated according to ISBD principles)
    if subfield_indicators.include?('e')
      subfield_indicators.each do |i|
        if i == 'e'
          e_index = subfield_indicators.index(i)
          target_subfield = subfields[e_index - 1]
          target_key = target_subfield.keys.first
          target_subfield[target_key].gsub!(/\+\s?$/,'')
          this_subfield = subfields[e_index]
          this_subfield[this_subfield.keys.first].gsub!(/^\&\s?/,'')
        end
      end
    end
    
    # if $c, get it's index, then find the element right before it and remove any trailing ';'
    if subfield_indicators.include?('c')
      subfield_indicators.each do |i|
        if i == 'c'
          c_index = subfield_indicators.index(i)
          target_subfield = subfields[c_index - 1]
          target_key = target_subfield.keys.first
          target_subfield[target_key].gsub!(/\;\s?$/,'')
        end
      end
    end
    
    # if $b, get it's index, then find the element right before it and remove any trailing ':'
    if subfield_indicators.include?('b')
      subfield_indicators.each do |i|
        if i == 'b'
          b_index = subfield_indicators.index(i)
          target_subfield = subfields[b_index - 1]
          target_key = target_subfield.keys.first
          target_subfield[target_key].gsub!(/\:\s?$/,'')
        end
      end
    end
  end
  
  
  def language_from_marc(tag,field)
    # 041 Language -> LANGCODE attribute in <language>
    # 546 Language -> <langmaterial>
    add_codes = Proc.new do |string|
      puts string + "add codes"
      if string.length == 3
        @lang_codes << string if !@lang_codes.include?(string)
      elsif string.length > 3        
        i = 0
        while string[i] do
          code = ''
          (i..i+2).to_a.each { |x| code += string[x] ? string[x] : ''}
          # Use only MARC lang codes - reject 2-digit values
          @lang_codes << code if (!@lang_codes.include?(code) && code.length == 3)
          i += 3
        end
      end
    end
    
    case tag
    when '041'
      @description[:data]['langmaterial_codes'] ||= []
      @lang_codes = @description[:data]['langmaterial_codes']
      
      # Get all (distinct) lang codes
      check_subfields = ['a','d','e','g','h','j','k','m','n']
      field[:subfields].each do |s|
        if check_subfields.include?(s.keys.first)
          puts s[s.keys.first] + "s[s.keys.first]"
          add_codes.call(s[s.keys.first])
        end
      end
    when '546'
      note = concatenate_subfields(tag,field)
      (@description[:data]['langmaterial'] ||= []) << { 'value' => note }
      m = note.scan(/[A-Z][a-z]+/)
      if m
        m.to_a.each do |l|
          code = language_string_to_code[l]
          if code
            @description[:data]['langmaterial_codes'] ||= []
            @lang_codes = @description[:data]['langmaterial_codes']
            if !@lang_codes.include?(code)
              @lang_codes << code
            end
          end
        end
      end
    end
    
  end
  
  # '340','500','506','510','524','530','535','536','538','540','544','555','581','770','773','774','787'
  def notes_from_marc(tag, field)
    note = { 'value' => "<p>#{concatenate_subfields(tag,field)}</p>" }
    case tag
    when '340','538'
      # 340 Physical medium <phystech>
      # 538 System Details  <phystech>
      (@description[:data]['phystech'] ||= []) << note      
    when '524'
      (@description[:data]['prefercite'] ||= []) << note
    when '506'
      # 506 Restrictions governing access <accessrestrict>
      (@description[:data]['accessrestrict'] ||= []) << note
    when '530'
      # 530 Additional physical form available  <altformavail>
      (@description[:data]['altformavail'] ||= []) << note
    when '535'
      # 535 Location of Originals/Duplicates  <originalsloc>
      (@description[:data]['originalsloc'] ||= []) << note
    when '536'
      # 536 Funding information <sponsor>
      (@description[:data]['sponsor'] ||= []) << note
    when '540'
      # 540 Terms governing use and reproduction  <userestrict>
      (@description[:data]['userestrict'] ||= []) << note
    when '544'
      # 544 Location of other archival materials  <relatedmaterial>
      (@description[:data]['relatedmaterial'] ||= []) << note
    when '770','773','774','787'
      case tag
      when '773'
        note['type'] = 'host'
      when '774'
        note['type'] = 'constituent'
      end
      # Stupid fix for Phorz
      if !note['value'].match('Carl H. Pforzheimer Collection of Shelley and His Circle: Manuscripts')
        (@description[:data]['relatedmaterial'] ||= []) << note
      end
      
    when '510','581'
      # 510 Citation/references <bibliography>
      # 581 Publications about described materials  <bibliography>
      (@description[:data]['bibliography'] ||= []) << note
    when '500','555'
      # 500 General note	<odd>/<note>
      # 555 Cumulative index/finding aids	(5)
      note['encodinganalog'] = tag
      (@description[:data]['note'] ||= []) << note
    end
  end
  
  
  def acqinfo_from_marc(tag,field)
    # 541 Immediate source of acquisition <acqinfo> # HARD
    if tag == '541'
      acqinfo = {}
      acqinfo['internal'] = true if field[:ind1] == '1'
      subfield_indicators = subfields_present(field)
      subfields = field[:subfields]
      subfield_indicators.each_index do |i|
        case subfield_indicators[i]
        when 'a'
          acqinfo['source'] ||= strip_stop(subfields[i]['a'])
        when 'b'
          acqinfo['address'] ||= strip_stop(subfields[i]['b'])
        when 'c'
          acqinfo['method'] ||= strip_stop(subfields[i]['c'])
        when 'd'
          acqinfo['date'] ||= strip_stop(subfields[i]['d'])
        when 'e'
          acqinfo['accession_number'] ||= strip_stop(subfields[i]['e'])
        when 'f'
          acqinfo['owner'] ||= strip_stop(subfields[i]['f'])
        when 'h'
          acqinfo['price'] ||= strip_stop(subfields[i]['h'])
        when 'n'
          extent = subfields[i]['n']
          if subfield_indicators[i + 1] == 'o'
            extent += " #{subfield_indicators[i + 1]['o']}"
          end
          acqinfo['extent'] ||= strip_stop(extent)
        when '3'
          acqinfo['materials'] ||= strip_stop(subfields[i]['3'])
        end
      end
      if acqinfo['source'] || acqinfo['method']
        # display_text = <materials>: <method>, <source>, <date> (<extent>)
        display_text = ''
        display_text += acqinfo['materials'] ? "#{acqinfo['materials']}: " : ''
        if acqinfo['method'] && acqinfo['source'] && acqinfo['date']
          display_text += "#{acqinfo['method']}, #{acqinfo['source']}, #{acqinfo['date']}"
        elsif acqinfo['method'] && acqinfo['source']
          display_text += "#{acqinfo['method']}, #{acqinfo['source']}"
        elsif acqinfo['source'] && acqinfo['date']
          display_text += "#{acqinfo['source']}, #{acqinfo['date']}"
        elsif acqinfo['method'] && acqinfo['date']
          display_text += "#{acqinfo['method']}, #{acqinfo['date']}"
        end
        acqinfo['value'] = "<p>#{display_text}</p>" if !display_text.blank?
      end
      (@description[:data]['acqinfo'] ||= []) << acqinfo
    end
  end
  
  
  def arrangement_from_marc(tag,field)
    #351 Organization and arrangement -> <arrangement>
    if tag == '351'
      (@description[:data]['arrangement'] ||= []) << { 'value' => concatenate_subfields(tag,field) }
    end
  end
  
  
  def parse_marc_852(record)
    # 852 Location	<repository>/<physloc>
    @call_numbers, @notes, @repository = [],[],[]
    
    # if multiple call numbers are present, need to track what version of materials it identifies
    get_call_numbers = Proc.new do |field,subfields|
      if subfields.include?('m')
        @call_numbers << "#{subfield_value(field,'h')} #{subfield_value(field,'m')}"
      else
        field[:subfields].each do |s|
          @call_numbers << s['h'] if s['h']
        end
      end      
      @call_numbers.uniq!
    end
    
    get_note = Proc.new do |field,subfields|
      if subfields.include?('z')
        field[:subfields].each do |s|
          if s['z']
            @notes << { 'value' => "<p>#{s['z']}</p>", 'encodinganalog' => '852$z' }
          end
        end
      end
      @notes.uniq!
    end
    
    get_repository = Proc.new do |field,subfields|
      repository = []
      field[:subfields].each do |s|
        repository << (s['a'] || s['e'])
      end
      (@repository << repository.join(' ')).uniq!
    end
    
    fields = record[:fields]['852'] || []
    
    fields.each do |f|
      subfields = subfields_present(f)
      if subfields.include?("h")
        get_call_numbers.call(f,subfields)
        if subfields.include?("z")
          get_note.call(f,subfields)
        end
      end
      if !(['a','e'] & subfields).empty?
        get_repository.call(f,subfields)
      end
    end

    # @call_numbers, @notes, @repository, @url
    @call_numbers.each do |c|
      @description[:data]['physloc'] ||= []
      physloc = {'value' => c, 'type' => 'local_call' }
      @description[:data]['physloc'] << physloc
    end
    
    @notes.each do |n|
      (@description[:data]['note'] ||= []) << n
    end
    
    @repository.each do |r|
      repository = { :value => r }
      (@description[:data]['repository'] ||= []) << repository
    end
    
  end
  
  
  # processes multiple 520 fields into a single value, stored in an array
  def abstract_scope_from_marc(record)
    fields = record[:fields]['520'] || []
    if !fields.empty?
      abstract = ''
      scopecontent = ''
      fields.each do |f|
        # 520 Summary, etc.	-> <scopecontent>/<abstract>
        if f[:ind1] == '3'
          abstract.strip!
          abstract += !abstract.blank? ? ' ' : ''
          abstract += concatenate_subfields('520',f)
        else
          scopecontent.strip!
          text = concatenate_subfields('520',f)
          scopecontent += !text.blank? ? "<p>#{punctuate_paragraph(text)}</p>" : ''
        end
      end
      if !abstract.blank?
        (@description[:data]['abstract'] ||= []) << { 'value' => remove_newlines(abstract) }
      end
      if !scopecontent.blank?
        (@description[:data]['scopecontent'] ||= []) << { 'value' => remove_newlines(scopecontent) }
      end
    end
  end
  
  
  # processes multiple 545 fields into a single value, stored in an array
  def bioghist_from_marc(record)
    # 545 Biographical or historical data -> <bioghist>
    # Multiple 545 fields will be treated as multiple paragraphs of a single bioghist
      # rather than as multiple instances of bioghist
    fields = record[:fields]['545'] || []
    if !fields.empty?
      bioghist = ''
      fields.each do |f|
        bioghist.strip!
        text = concatenate_subfields('545',f)
        bioghist += !text.blank? ? "<p>#{punctuate_paragraph(text)}</p>" : ''
      end
      (@description[:data]['bioghist'] ||= []) << { 'value' => remove_newlines(bioghist) }
    end
  end
  
  # processes multiple 545/561 fields into a single value, stored in an array
  def custodhist_from_marc(record)
    # 561 Ownership and custodial history -> <custodhist>
    # Multiple 561 fields will be treated as multiple paragraphs of a single custodhist
      # rather than as multiple instances of custodhist
    fields = record[:fields]['561'] || []
    if !fields.empty?
      custodhist = ''
      fields.each do |f|
        custodhist.strip!
        text = concatenate_subfields('561',f)
        custodhist += !text.blank? ? "<p>#{punctuate_paragraph(text)}</p>" : ''
      end
      (@description[:data]['custodhist'] ||= []) << { 'value' => remove_newlines(custodhist) }
    end
  end
  

## END - Helper methods for description_from_marc()


## BEGIN - General use helper methods for working with MARC hash (keyed on tag)

  # Provides last 2 digits of tag
  def tag_xx(tag)
    xx = tag[1] + tag[2]
  end
  
  
  # Provides field range expressed as an integer divisible by 100 (eg 100, 200, 300, etc)
  def tag_range(tag)
    range = tag[0] + 'xx'
  end


  # Concatenates applicable subfields to provide element value
  def concatenate_subfields(tag,field)
    if ['1xx','6xx','7xx'].include?(tag_range(tag)) && !('770'..'787').to_a.include?(tag)
      use_subfields = access_term_value_subfields(tag)
    else
      use_subfields = value_subfields(tag)
    end
    values = []
    field[:subfields].each do |s|
      s_indicator = s.keys.first
      if use_subfields.include?(s_indicator)
        values << s[s_indicator].strip
      end
    end
    subject_tags = ['650','651','655','656','657','690','691','752']    
    if subject_tags.include?(tag)
      values.map { |v| strip_stop(v) }
      values.join(' -- ')
    else
      strip_stop(values.join(' '))
    end
  end


  # subfields to concatenate to form element value (returns hash keyed on tag)
  # NOTE: subfield array contains single-element hashes in the form { subfield_code => value }
  def value_subfields(tag)
    subfields = {
      '245' => ['a','b','c','h','k','n','p','s'], # removed $f & $g (dates)
      '240' => ['a','d','f','g','h','k','l','m','n','o','p','r','s'],
      '340' => ['a','b','c','d','e','f','h','i','j','k','m','n','o'],
      '351' => ['a','b','c','3'],
      '506' => ['a','b','c','e','3'],
      '500' => ['a','3'],
      '510' => ['a','b','c','u','x','3'],
      '520' => ['a','b','c','u','2','3'],
      '524' => ['a','3'],
      '530' => ['a','b','c','d','u','3'],
      '535' => ['a','b','c','d','g','3'],
      '536' => ['a'],
      '538' => ['a','i'],
      '540' => ['a','b','c','3'],
      '544' => ['a','b','c','e','n','3'],
      '545' => ['a','b'],
      '546' => ['a','b','3'],
      '555' => ['a','b','c','d','3'],
      '561' => ['a','b','3'], # NOTE: $b is not valid for 561, but a few instances of its use were found in existing records.
      '581' => ['a','z','3'],
      '770' => ['a','b','c','d','g','h','i','k','m','n','o','r','s','t']
    }
    subfields['773'] = subfields['770']
    subfields['774'] = subfields['770']
    subfields['787'] = subfields['770']
    subfields[tag]
  end
  
  
  # subfields to concatenate to form element value for access term fields (returns hash keyed on 'xx' portion of tag)
  # NOTE: subfield array contains single-element hashes in the form { subfield_code => value }
  def access_term_value_subfields(tag)
    subfields = {
      '00' => ['a','b','c','d','j','f','g','k','l','p','q','t','u'],
      '10' => ['a','b','c','d','f','g','k','l','n','p','t','u'],
      '11' => ['a','c','d','e','q'],
      '30' => ['a','n','p','l','f','k','s','d','h','m','o','r','g','t','v','x'],
      '40' => ['a','h','n','p'],
      '50' => ['a','b','c','d','v','x','y','z'],
      '51' => ['a','v','x','y','z'],
      '52' => ['a','b','c','d','f','g','h'],
      '53' => ['a'],
      '55' => ['a','b','v','x','y','z'],
      '56' => ['a','k','v','x','y','z'],
      '57' => ['a','v','x','y','z']
    }
    if ('690'..'699').to_a.include?(tag)
      subfield_analogs = {'690' => '50', '691' => '51', '696' => '00',
        '697' => '10', '698' => '11', '699' => '30'}
      subfields[subfield_analogs[tag]]
    elsif ('790'..'799').to_a.include?(tag)
      subfield_analogs = {'790' => '00', '791' => '10', '792' => '11',
        '793' => '30', '796' => '10', '797' => '10', '798' => '11', '799' => '30'}
      subfields[subfield_analogs[tag]]
    else
      subfields[tag_xx(tag)]
    end
  end

  
  # Returns an array containing indicators for all subfields present in field (in order)
  def subfields_present(field)
    indicators = []
    field[:subfields].each do |s|
      indicators << s.keys.first
    end
    indicators
  end
  

  def access_term_type(tag,field)
    if ('690'..'699').to_a.include?(tag)
      # 'subject'
      'topic'
    else
      case tag_xx(tag)
      when '00','90','96'
        field[:ind1] == '3' ? 'famname' : 'persname'
      when '10','11','91','92','97','98'
        'corpname'
      when '30','40','93','99'
        'title'
      when '50','53'
        'topic'
      when '51','52'
        'geogname'
      when '55'
        'genreform'
      when '56'
        'occupation'
      when '57'
        'function'
      end
    end
    
  end
  
  
  def subject_thesaurus_code(tag,field)
    indicator_2_values = {
      '0' => 'lcsh',
      '1' => 'lcshac',
      '2' => 'mesh',
      '3' => 'nal',
      '4' => nil,
      '5' => 'cash',
      '6' => 'rvm'
    }
    if tag_range(tag) == '6xx'
      if field[:ind2] == '7'
        subfield_value(field,'2')
      else
        indicator_2_values[field[:ind2]]
      end
    else
      nil
    end
  end
  
  
  def relator_from_subfields(tag,field)
    relator = {}
    if ['1xx','6xx','7xx','8xx'].include?(tag_range(tag))
      relator[:code] = subfield_value(field,'4')
      relator[:term] = tag_xx(tag) == '51' ? subfield_value(field,'4') : subfield_value(field,'e')
    end
    relator[:term] ||= relator[:code] ? marc_relators(relator[:code])[:label] : nil
    relator.each { |k,v| strip_stop(v) if v }
    compact(relator)
    relator.blank? ? nil : relator
  end
  
  
  # returns the value of subfield if present, or value of first instance if subfield is repeated
  def subfield_value(field,subfield_indicator)
    value = nil
    field[:subfields].each do |s|
      if s.keys.first == subfield_indicator
        value = !s[s.keys.first].blank? ? s[s.keys.first].strip : nil
        break
      end
    end
    strip_stop(value) if value
  end
  

  # ensures that paragraph text ends with a period
  def punctuate_paragraph(string)
    if !string.match(/[\.\?\!]$/)
      string += '.'
    end
  end
  
  
  def org_unit_id_from_marc(record)
    nil
  end
  
end