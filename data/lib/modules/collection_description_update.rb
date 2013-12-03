module CollectionDescriptionUpdate
    
  def self.update_supress_arrangement_display
    find_each { |c| c.supress_arrangement_display }
  end
  
  
  def update_supress_arrangement_display
    spread = 40
    use_scope = lambda do |scope_value,arrangement_value|
      if scope_value && arrangement_value
        scope_test = strip_tags(scope_value)
        arrangement_test = strip_tags(scope_value)
        [scope_test,arrangement_test].each { |t| t.gsub!(/[\s\n\r\t]/,'') }
        return (scope_test.length + spread) > arrangement_test.length ? true : false
      else
        return false
      end
    end
    
    data = JSON.parse(self.description.data)
    
    # reset
    if !data['arrangement'].blank?
      data['arrangement'].each { |a| a['supress_display'] = nil }
    end
    
    if data['scopecontent'] && data['arrangement']
      data['scopecontent'].each do |s|
        if s['type'] == 'arrangement'
          if use_scope.call(s['value'], data['arrangement'][0]['value'])
            data['arrangement'][0]['supress_display'] = true
          end
          break
        end
      end
    end  
    
    compact(data)
    self.description.update_attribute(:data, JSON.generate(data))  
  end
  
  
  def enhance_description(data = nil)
    data ||= self.description_data
    self.add_series_scope_to_collection_scope(data)
    self.generate_expanded_abstract(data)
  end


  def add_series_scope_to_collection_scope(data)
    collection_data = data || self.description_data
    
    series = self.series
    
    if self.title.strip.match(/[Cc]ollection\sof\s[Pp]apers$/)
      is_are = "is"
    else
      is_are = self.title.strip.match(/[s]$/) ? 'are' : 'is'
    end
    
    update = nil
    
    # remove existing arrangement from scopecontent if it exists
    if collection_data['scopecontent']
      collection_data['scopecontent'].each do |sc|
        if sc['type'] == 'arrangement'
          collection_data['scopecontent'].delete(sc)
          update = true
        end
      end
    end
    if collection_data['arrangement']
      collection_data['arrangement'].each do |a|
        a.delete('supress_display')
      end
      update = true
    end
      
    if series && (series.length > 1)

      collection_scope = "<p class='list-head'>The #{self.title} #{is_are} arranged in #{number_to_text(series.length)} series:</p>\n"
      
      # class will be added to wrapper if no series-level scope is present
      series_scope_present = nil
      
      series_content = ''
      
      series.each do |s|
        series_content += "<li>"
        
        # ADDING LINK TO SERIES HERE LIMITS USE OF THIS DATA OUTSIDE PORTAL - CONSIDER ALTERNATIVE

        series_content += "<div class='series-title'><a href='#{s.persistent_path}'>#{s.title}</a></div>\n"
        
        if s.date_statement
          series_content += "<div class='series-date'>#{s.date_statement}</div>\n"
        end
        
        if s.extent_statement
          series_content += "<div class='series-extent'>#{s.extent_statement}</div>\n"
        end
        
        data = JSON.parse(s.description.data)
        if data['scopecontent']
          series_content += "<div class='series-description'>"

          # series_scope_present = true
          data['scopecontent'].each do |sc|
            series_content += sc['value'] if sc['value']
          end
          series_content += "</div>"
        end
        series_content += "</li>"
      end
      if !series_content.blank?
        collection_scope += "<ul class='arrangement series-descriptions'>\n"
        collection_scope += series_content
        collection_scope += "</ul>\n"
      end
      
      # wrapper_class = series_scope_present ? "arrangement series-descriptions" : "arrangement series-list"
      # collection_scope += "<div class='#{wrapper_class}'>#{series_content}</div>"

      (collection_data['scopecontent'] ||= []) << { 'value' => collection_scope, 'type' => 'arrangement' }
      
      if collection_data['arrangement']
        collection_data['arrangement'][0]['supress_display'] = true
      end
      
      compact(collection_data)
      update = true
    end
    if update
      self.description.update_attributes(:data => JSON.generate(collection_data))
    end
  end
  
  
  def generate_prefercite(data = nil,options = {})
    # New York World's Fair 1939-1940 records, Manuscripts and Archives Division, The New York Public Library
    data ||= self.description_data
    if !data['prefercite'] || options[:force]
      prefercite = self.title
      prefercite += ", " + self.org_unit.name
      prefercite += ", The New York Public Library"
      (data['prefercite'] ||= []) << { :value => prefercite }
      self.description.update_attributes(:data => JSON.generate(data))
    end
  end
  
  
  def generate_expanded_abstract(data = nil)
    data ||= self.description_data
    
    abstract_needed = nil
    
    # remove existing generated abstract if it exists
    if data['abstract']
      data['abstract'].each do |a|
        if a['generated']
          data['abstract'].delete(a)
          if data['abstract'].empty?
            data.delete('abstract')
            # unset supress_display on scope/bioghist
            if data['scopecontent'] && data['scopecontent'][0]
              data['scopecontent'][0]['supress_display'] = nil
            end
            if data['bioghist'] && data['bioghist'][0]
              data['bioghist'][0]['supress_display'] = nil
            end
            abstract_needed = true
          end
        end
      end
    else
      abstract_needed = true
    end
    
    
    if abstract_needed
      generate_abstract = nil
      scope_abstract = ''
      bio_abstract = ''
      original_abstract = data['abstract'] ? data['abstract'][0]['value'].strip : ''
    
      # Only bother with abstracts that were generated from scope, or collections without abstract
      # TBD - How to regulate this moving forward?
      if data['scopecontent'] && data['scopecontent'][0]
        scope_html = data['scopecontent'][0]['value']
        doc = Nokogiri::XML("<scopecontent>#{scope_html}</scopecontent>")
        paragraphs = doc.root.xpath('./p')
        if !paragraphs.empty?
          scope_abstract += paragraphs.first.inner_html.strip
        
          # Abstract will be generated if not present or identical to scope_abstract          
          if (scope_abstract == original_abstract) || original_abstract.blank?
            generate_abstract = true
            # Scope will be generated from first paragraph of abstract if more than 1
            if paragraphs.length == 1
              data['scopecontent'][0]['supress_display'] = true
            end
          end
        end
      end
    
      if data['bioghist'] && data['bioghist'][0]
        bio_html = data['bioghist'][0]['value']
        doc = Nokogiri::XML("<bioghist>#{bio_html}</bioghist>")
        paragraphs = doc.root.xpath('./p')
        if paragraphs && paragraphs.length == 1
          bio_abstract += paragraphs.first.inner_html.strip
          if !generate_abstract && !data['scopecontent']
            generate_abstract = true
          end
        end
      end
    
      if generate_abstract
        if !bio_abstract.empty?
          data['bioghist'][0]['supress_display'] = true
        end
        new_abstract = bio_abstract + " " + scope_abstract
        data['abstract'] = [{'value' => new_abstract, 'generated' => true }]        
        puts "ABSTRACT: " + new_abstract
      
        compact(data)
        self.description.update_attributes(:data => JSON.generate(data))
      end
    end
  end
  
  
  
  # For when there was crap in the EAD and you imported it, overwriting the non-crap from the catalog
  # if replace = true, existing data is replaced, otherwise new data is added only if old ones don't already exist
  def update_description_element_from_catalog(element, replace = true)
    require 'json'
    
    replace_element_value = Proc.new do |new_data|
      d = self.description
      data = JSON.parse(d[:data])
      new_data.each do |k,v|
        if replace || !data[k]
          data[k] = v
        end
      end
      compact(data)
      d.update_attribute(:data, JSON.generate(data))
    end
    
    if self.bnumber
      import = CatalogImport.new(:collection_id => self.id, :bnumber => self.bnumber)
      puts element
      case element
      when 'abstract'
        new_data = import.get_element_from_marc('abstract')
        if new_data
          replace_element_value.call(new_data)
        end
      when 'langmaterial'
        new_data = import.get_element_from_marc('langmaterial')
        if new_data
          replace_element_value.call(new_data)
        end
      when 'physdesc'
        new_data = import.get_element_from_marc('physdesc')
        if new_data
          replace_element_value.call(new_data)
        end
      end
    end
  end
  
  
  # orignal ingest did not pull data from 'author' element in eadheader or frontmatter,
  # but that's where the processing archivist gets credit, so fix that
  def get_author_from_ead(options)
    if !options[:filepath]
      raise "Collection#get_author_from_ead: no filepath provided"
    else options[:filepath]
      @source = open(options[:filepath])
      data = self.description_data
      
      begin

        @doc = Nokogiri::XML(@source)
        @doc.remove_namespaces!
        @ead = @doc.root()
        if @ead
          @eadheader = @ead.xpath('./eadheader').first
          @frontmatter = @ead.xpath('./frontmatter').first
          @archdesc = @ead.xpath('./archdesc').first
        end
      
        eadheader_author = @eadheader ? @eadheader.xpath('./filedesc/titlestmt/author').to_a : []
        frontmatter_author = @frontmatter ? @frontmatter.xpath('./titlepage/author').to_a : []
        author = !eadheader_author.empty? ? eadheader_author : frontmatter_author
      
        author.uniq!

        if !author.empty?
          author.reverse.each do |a|
            value = a.inner_text
            remove_newlines(value)
            if !value.match(/\.\s?$/)
              value += '.'
            end
            
            value = "<p>#{value}</p>"
            
            # get existing processinfo to check against
            existing_processinfo_values = []
            if data['processinfo']
              data['processinfo'].each { |p| existing_processinfo_values << p['value'] }
            end
            
            if !existing_processinfo_values.include?(value)
              (data['processinfo'] ||= []).insert(0,{ 'value' => value }) if value
            end
          end
          self.description.update_attributes(:data => JSON.generate(data))
        end
      rescue Exception => e
        puts e
      end
    end
  end


  def remove_standard_accessrestrict(data = nil)
    data ||= self.description_data
    if data.has_key?('accessrestrict')
      data['accessrestrict'].each do |a|
        if a['value']
          new_value = clean_accessrestrict(a['value'])
          if !new_value.blank?
            a['value'] = new_value
          else
            index = data['accessrestrict'].index(a)
            data['accessrestrict'].delete_at(index)
          end
        end
      end
      compact(data)
      self.description.update_attributes(:data => JSON.generate(data))
    end
  end

  
  # For data imported from MARC, 555 often references online finding aid
  def remove_findingaid_reference(data = nil)
    data ||= self.description_data
    if data.has_key?('note')
      data['note'].each do |n|
        if (n['encodinganalog'] == '555') && n['value']
          new_value = clean_555(n['value'])
          if new_value != n['value']
            if !new_value.blank?
              n['value'] = new_value
            else
              index = data['note'].index(n)
              data['note'].delete_at(index)
              compact(data)
            end
            self.description.update_attributes(:data => JSON.generate(data))
          end
        end
      end
    end
  end
  
  
  
  
  
  def supress_physloc_call_numbers
    data = JSON.parse(self.description.data)
    if data['physloc'] && !self.call_number.blank?
      data['physloc'].each do |p|
        if p['type'] == 'local_call'
          p['supress_display'] = true
        end
      end
      self.description.update_attributes(:data => JSON.generate(data))
      self.reload
      self.update_response(:limit => 'desc_data')
    end
  end
  
  def supress_call_number_in_description(data=nil)
    if self.call_number
      data ||= self.description_data
      if data['unitid']
        puts data['unitid'].inspect
        data['unitid'].each do |u|
          if u['type'] == 'local_call' && (u['value'] == self.call_number)
            u['supress_display'] = true
          end
        end
      end
      
      if data['physloc']
        data['physloc'].each do |p|
          if p['type'] == 'local_call' && (p['value'] == self.call_number)
            p['supress_display'] = true
          end
        end
      end
      
      self.description.update_data(data)
    end
  end
  
  
  protected
  
  
  def clean_accessrestrict(string)
    new_string = string.clone
    new_string.gsub!(/\<\/?p\>/,'')
    remove_newlines(new_string)
    r = {
      :separator => '\s?[\;\.\,]\s?',
      :optional_separator => '[\s\;\.\,]*',
      # Restricted access
      :restricted_access => 'Restricted\s[Aa]ccess',
      # Permit must be requested at the division indicated
      :permit => '[Pp]ermit\smust\sbe\srequested\sat\s(the\s)?division\sindicated',
      # request permission from holding division
      :request_permission => '[Rr]equest\spermission\s(from\s)?(in\s)?(at\s)?holding\sdivision',
      # Access restricted ;
      :access_restricted => '[Aa]ccess\s[Rr]estricted',
      :mss_web => '[Aa]ppl?y(\sto\sManuscripts\sand\sArchives\sDivision)?(\sfor\saccess)?(\sfor\suse)?\sat\:?\s(http\:\/\/)?(www\.)?nypl\.org\/mss(ref)?',
      :advance_notice => '[Aa]dvanced?\snoti(fication)?(ce)?(\sis)?(\smay\s?be)?\srequired(\s?for\suse)?(\s?for\saccess)?(\sof\sManuscripts\sand\sArchives\sDivision\smicrofilm)?',
      :for_access => 'For\saccess(\sto\sthe\scollection)?[\s\,]*contact\s(the\s)?(curator)?(director)?(\sof\sthe\sarchive)?',
      :open => '(The)?\s?[Cc]ollection\s?(is)?\s?(open)?\s?(available)?\s(to)?\s?(for)?\s(the\spublic)?\s?(research)?',
      :photocopying => 'Library\spolic(y)|(ies)\son\s(photoc?o?pying)?(photography)?(\sand\s)?(photoc?o?pying)?(photography)?\swill\sapply',
      :microfilm1 => 'Microfilms?\,?\s?(and)?(or)?\s?(digital\simages)?\,?\s?(and)?(or)?\s?(copy\sprints)?',
      :microfilm2 => '(in Microforms Division or Manuscripts and Archives Division)?(of letter books and letters from Frances Hodgson Burnett)?(of Winston Churchill correspondence)?',
      :microfilm3 => 'must\sbe\sused\s?(in\s(lieu)?(place)?\sof)?\s?(the)?\s?(originals?)?\s?(volumes?)?(diary)?(journal and transcript)?(manuscripts?)?(\s?and negative photostat copy)?(materials?)?(papers?)?(records?)?\s?(when available)?',
      :use_requires_notice => 'Use of (this)?(these)? (collections?)?(items?)? requires? advance notice',
      :inquire => 'Inquire at (reference\s)?desk for (register)?\s?(and)?\s?(folder\slist)?\s?(finding\said)?',
      :special_handling => 'Special [Hh]andling',
      :apply => 'Apply to (the\s)?(Dance)?(Theater)?(Music)?\s?(Collection)?(Division)?',
      :no_restrictions => '(There are)?\s?[Nn]o restrictions\s?(to)?(on)?\s?(access)?'
      
#       Inquire at reference desk for register and folder list.
# Special Handling
# Apply to Dance Collection.

    }
    patterns = [
      "#{r[:restricted_access]}#{r[:separator]}.*#{r[:permit]}#{r[:optional_separator]}",
      "#{r[:restricted_access]}#{r[:separator]}.*#{r[:request_permission]}#{r[:optional_separator]}",
      "#{r[:access_restricted]}#{r[:separator]}",
      "#{r[:advance_notice]}#{r[:separator]}",
      "#{r[:access_restricted]}#{r[:optional_separator]}#{r[:advance_notice]}#{r[:optional_separator]}",
      "#{r[:mss_web]}#{r[:optional_separator]}",
      "#{r[:for_access]}#{r[:optional_separator]}",
      "Apply in Speical Collections Office for admission to the Manuscripts and Archives Division#{r[:optional_separator]}",
      "#{r[:advance_notice]}#{r[:optional_separator]}$",
      "#{r[:photocopying]}#{r[:optional_separator]}",
      "#{r[:open]}#{r[:optional_separator]}(with some materials only available in surrogate form)?#{r[:optional_separator]}",
      "#{r[:open]}#{r[:optional_separator]}",
      "Advance written permission of\s?(the)?\s?Curator of Manuscripts\s?(is)?\s?required#{r[:optional_separator]}",
      "Available only b[ey]\s?(advance)?\s?(written)?\s?permission of\s?(the)?\s?Curator of Manuscripts#{r[:optional_separator]}",
      "#{r[:microfilm1]}\s?#{r[:microfilm2]}\s?#{r[:microfilm3]}#{r[:optional_separator]}",
      "#{r[:use_requires_notice]}#{r[:optional_separator]}",
      "[Uu]nrestricted#{r[:optional_separator]}",
      "Use of originals? must be approved by Curator of Manuscripts#{r[:optional_separator]}",
      "Permission of curator( is)? required#{r[:optional_separator]}",
      "Readers must use (microfilm)?(copies of fragile letters)?( (in lieu)?(instead)? of originals)?",
      "#{r[:inquire]}#{r[:optional_separator]}",
      "#{r[:special_handling]}#{r[:optional_separator]}",
      "#{r[:apply]}#{r[:optional_separator]}",
      "^folder list#{r[:optional_separator]}$",
      "^[Rr]equired#{r[:optional_separator]}$",
      "^[Ii]nquire at reference desk\s?(for)?\s?#{r[:optional_separator]}$",
      "^[Nn]o restirctions#{r[:optional_separator]}$",
      "^#{r[:no_restrictions]}#{r[:optional_separator]}$",
      "^[Uu]nrestricted#{r[:optional_separator]}$",
      "Apply in (the)?\s?(Special Collections Office)?(Room 328)?\s?(for admission to)?\s?(the)?\s?(Manuscripts and Archives Division)?#{r[:optional_separator]}",
      "Advance notice required#{r[:optional_separator]}Apply at http\:\/\/www.nypl.org\/mssref#{r[:optional_separator]}",
      "Apply to Manuscripts and Archives Division for access at http\:\/\/www.nypl.org\/mssref#{r[:optional_separator]}"
    ]
    patterns.each do |p|
      new_string.gsub!(/\s{2,}/,' ')
      regex = Regexp.new(p)
      new_string.gsub!(regex,'')
    end
    new_string.strip!
    new_string.gsub!(/\s?[\;\,\:]$/,'.')
    if !new_string.match(/\.$/)
      new_string += '.'
    end
    if new_string.match(/^[^\w]*$/)
      new_string = ''
    end
    new_string = (new_string.length > 5) ? "<p>#{new_string}</p>" : ''
  end
  
  
  def clean_555(string)
    new_string = string.clone
    new_string.gsub!(/\<\/?p\>/,'')
    remove_newlines(new_string)
    r = {
      :separator => '\s?[\;\.\,]\s?',
      :optional_separator => '[\s\;\.\,]*',
    }
    patterns = [
      "^([Ff]inding)?([Ff]older)?\s([Aa]id)?([Ll]ist)?.*$",
      "^For finding aid see librarian.*$",
      "^(Collection [Gg]uide)?([Ff]inding)?\s?([Aa]id)?\s?(\(i.e. Finding aid\))?\s?(is)?\s?available.*$",
      "^Container list.*$",
      "^Detailed.*$",
      "^Complete.*$",
      "For finding aid see librarian",
      "^Preliminary.*$",
      "^Partial.*$",
      "^Unpublished.*$",
      "^.*[Ii]nternet.*$",
      "Contents and separation lists in the repository",
      "Contents list in the repository",
      "Guide to the collection available online",
      "Box list",
      "Contents and separation lists in the repository",
      " Published finding aid available for microfilm copy",
      "^Inventor(y)?(ies)? available"
    ]
    patterns.each do |p|
      new_string.gsub!(/\s{2,}/,' ')
      regex = Regexp.new(p)
      new_string.gsub!(regex,'')
    end
    new_string.strip!
    new_string.gsub!(/\s?[\;\,\:]$/,'.')
    if new_string.match(/^[^\w]*$/)
      new_string = ''
    end
    if new_string.match(/([Cc]atalog [Cc]ards)|(([Cc]ard)|([Cc]age) catalog)/)
      new_string = "Card catalog available."
    end
    new_string = (new_string.length > 5) ? "<p>#{new_string}</p>" : ''
  end


  
  
  
  
  
end