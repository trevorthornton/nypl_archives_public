module CollectionsHelper
  
  include ApplicationHelper
  include DescriptionHelper
  
  def section_elements
    { 'descriptive_identity' => ['origination', 'call_number','physdesc','abstract','langmaterial',
      'materialspec','prefercite','odd','sponsor','org_unit_name','physloc','extent_statement','standard_access_note'],
      'bioghist' => ['bioghist'],
      'content_structure' => ['scopecontent','arrangement'],
      'acquisition_processing' => ['custodhist','acqinfo','appraisal','processinfo','separatedmaterial','accruals'],
      # 'resources' => [],
      'bibliography' => ['bibliography'],
      'controlaccess' => ['name','subject','geogname','occupation','genreform','title'],
      'access_use' => ['container','physical_location','standard_access_note','userestrict','accessrestrict','legalstatus','phystech', 'altformavail','originalsloc','otherfindaid']
      
    }
  end

  
  def generate_description_sections
    @sections = {}
    @display_elements = {}
    
    section_elements.each do |k,v|
      
      v.each { |e| @display_elements[e] = element_data(e, @collection_data) }

      if k == 'descriptive_identity'
        generate_descriptive_identity_section_content(v)
      else
        section_content = []
        v.each do |element|
          if @display_elements[element] && !@display_elements[element]['content'].blank?
            section_content << generate_description_element(element)
          end
        end
        

        if k != 'controlaccess' && !section_content.empty?
          @sections[k] = "<div class='description-section description-section-#{k.gsub(/\_/,'-')}'>\n"
          @sections[k] += "<h2>#{description_section_labels(k)}</h2>\n"
          @sections[k] += section_content.join("\n")
          @sections[k] += '</div>'
        elsif k == 'controlaccess'
          
          if @collection_data['controlaccess']
            controlaccess_headings = { 'name' => 'Names', 'genreform' => 'Material types', 'subject' => 'Subjects', 'geogname' => 'Places', 'occupation' => 'Occupations', 'title' => 'Titles' }
            controlaccess = ''
            controlaccess += "<div class='element'>\n"
            controlaccess += "<h2>#{description_section_labels('controlaccess')}</h2>\n"
    
            section_elements['controlaccess'].each do |term_type|
              if @collection_data['controlaccess'][term_type]
                controlaccess += "<h3>#{controlaccess_headings[term_type]}</h3>\n"
                controlaccess += "<ul>\n"
                @collection_data['controlaccess'][term_type].each do |t|
                  controlaccess += "<li>" + link_to(t['term'], "/controlaccess/#{t['id']}?term=#{t['term']}")
                  if t['role'] && t['role'] != ('subject' || 'Subject')
                    controlaccess += " (#{t['role']})"
                  end
                end
                controlaccess += "</ul>\n"
              end
            end
    
            controlaccess += "</div>\n"
    
            @sections['controlaccess'] = "<div class='description-section description-section-controlaccess'>"
            @sections['controlaccess'] += controlaccess
            @sections['controlaccess'] += "</div>"
          end
          
        end

      end
    end
    
    
    
    
    if @collection_data['resources']
      resources = "<div class='element'>\n"
      resources += "<h2>#{description_section_labels('resources')}</h2>\n"
      resources += "<ul>\n"
      @collection_data['resources'].each do |r|
        resources += "<li>" + link_to(r['title'],r['url'])
        if r['file_type'] && file_type_labels[r['file_type']]
          resources += " (#{file_type_labels[r['file_type']]})"
        end
        if r['description']
          resources += "<br/>#{r['description']}"
        end
        resources += "</li>\n"
      end
      resources += "</ul>\n</div>\n"
       @sections['resources'] = resources
    end
    
    
    @sections
  end
  
  
  def generate_descriptive_identity_section_content(elements)

    puts "-----------~_~_~_~_~__~_~_~_~_~_~_~_~__~_~_----------------"
    @collection_data.each do |k,v|
      puts k,v
    end
    puts "-----------~_~_~_~_~__~_~_~_~_~_~_~_~__~_~_----------------"

    puts '@display_elements'
    puts @display_elements.inspect
    
    section_content = []
    if @display_elements['abstract']
      abstract_data = @display_elements.delete('abstract') { |k| nil }
      if !abstract_data['content'].blank?
        abstract = "<p class='abstract'"
        abstract += abstract_data['property'] ? " property='#{abstract_data['property'].join(' ')}'" : ''
        abstract += ">#{abstract_data['content']}</p>"
      end
    end
    
    if @display_elements['sponsor']
      sponsor_data = @display_elements.delete('sponsor') { |k| nil }
      if !sponsor_data['content'].blank?
        sponsor = "<p class='sponsor-note'"
        sponsor += sponsor_data['property'] ? " property='#{sponsor_data['property'].join(' ')}'" : ''
        sponsor += ">#{sponsor_data['content']}</p>"
      end
    end
    
    # if @display_elements['accessrestrict']
    #   accessrestrict_data = @display_elements.delete('accessrestrict') { |k| nil }
    #   if !accessrestrict_data['content'].blank?
    #     access_note = "<p class='access-note'><span class='heading'>Access conditions:</span> #{accessrestrict_data['content']}</p>"
    #   end
    # end
    
    elements.each do |element|
      if @display_elements[element] && !@display_elements[element]['content'].blank?
        if element != 'sponsor'
          
          
          element_output = "<dt>#{@display_elements[element]['label']}</dt>\n"
          
          if @display_elements[element]['property']
            element_output +=  "<dd property='#{@display_elements[element]['property'].join(' ')}'>"
          else
            element_output += "<dd>"
          end
          
          element_output += @display_elements[element]['content']
          
          if element == 'standard_access_note'
            element_output += access_restrictions_link
          end
          
          element_output += "</dd>"
          
          section_content << element_output
          
        end
      end
    end

    if @collection_data['digital_assets']
      section_content << "<dt></dt><dd class='digitized-material-note'>Portions of this collection have been digitized and are available online.</dd>"
    end
    
    
    if !section_content.empty?
      @sections['descriptive_identity'] = "<div class='description-section description-section-descriptive_identity'>"
      
      @sections['descriptive_identity'] += "<div class='collection-summary'>"
      @sections['descriptive_identity'] += "<dl class='dl-horizontal'>\n"
      @sections['descriptive_identity'] += section_content.join("\n") + "</dl>\n"
      @sections['descriptive_identity'] += "</div>"
      
      @sections['descriptive_identity'] += abstract ? abstract : ''
      @sections['descriptive_identity'] += sponsor ? sponsor : ''
      # @sections['descriptive_identity'] += access_note ? access_note : ''
      @sections['descriptive_identity'] += "</div>"
    end



  end
  
  
  def description_section_labels(section)
    labels = {
      'descriptive_identity' => "Collection Overview",
      'bioghist' => "Biographical/historical information",
      'content_structure' => "Scope and arrangement",
      'acquisition_processing' => "Administrative information",
      'bibliography' => "Bibliography",
      'resources' => "Additional resources",
      'controlaccess' => "Key terms",
      'access_use' => "Using the collection"
    }
    labels[section]
  end
  
  
  def generate_description_element(element, heading='h2')
    output = ''
    no_heading = ['bioghist','scopecontent','bibliography']
    if !@display_elements[element]['content'].blank?
      output += "<div class='element #{element}' id='#{element}'>"
      if !no_heading.include?(element)
        output += @display_elements[element]['label'] ? "<h3>#{@display_elements[element]['label']}</h3>" : ''
      end
      output += @display_elements[element]['content']
      output += '</div>'
    end
    output
  end


  def generate_inline_series_collection(series)
    output = ''
    output =+ '<script>'
    output =+ "All_Series = new Series_Collection(<%= series.to_json %>);"
    output =+ '</script>'
    output
  end
  
  
  # Fetches collection either by id or identifier value, depending on params present
  def variable_collection_find
    collection = nil
    if params[:find_by_identifier]
      options = { :identifier_value => params[:identifier_value] }
  		collection = Collection.includes(:collection_response, :org_unit).where(options).first
    elsif params[:id]
  		collection = Collection.includes(:collection_response, :org_unit).find params[:id]
    end
    collection
  end



  def build_component(json)

    data = JSON.parse(json.desc_data)
    hasOrigination = (data['origination']) ? true : false
    hasContainer = (data['container']) ? true : false
    hasDigitalAsset = (data['image']) ? true : false
    hasUnitid= (data['unitid']) ? true : false      

    field_list = ['title','date_statement','extent_statement','abstract','origination','controlaccess','bioghist','scopecontent','note','physloc','arrangement','accessrestrict','arrangement','appraisal','langmaterial', 'odd']
    field_values = {}

    field_list.each do |i|
      if (data[i])
        field_values[i] = ""
        if data[i].kind_of?(Array)
          data[i].each do |v|
            if v['value']
              field_values[i] = field_values[i] + v['value']
            end
          end
        end

        if data[i].kind_of?(String)
          field_values[i] = data[i]
        end

        if data[i].kind_of?(Hash)
          data[i].each do |v|
            v.each do |h|
              if h.kind_of?(Array) 
                h.each do |x|
                  if x['term']
                    field_values[i] = field_values[i] + x['term']
                  end
                  if x['role']
                    field_values[i] = field_values[i] + ' (' + x['role'] + ')'
                  end
                end                  
              end                               
            end              
          end
        end
      end
    end


    displayContainerTypeFull = ''
    if (hasContainer)
      displayContainerType = ''
      displayContainerValue = ''
      data['container'].each do |c|
        if c['type']
          displayContainerType = c['type'][0] + '. '
        end
        if c['value']
          displayContainerValue = c['value']
        end
        displayContainerTypeFull = displayContainerTypeFull  + displayContainerType + displayContainerValue + ' '
      end
    else    
      #there is no container
      if hasUnitid
        data['unitid'].each do |u|
          if (u['type'])
            if (u['type'] != "local_mss" && u['type']!= "local_barcode" &&  u['type'] != nil)                 
              if (u['value'])
                displayContainerTypeFull = displayContainerTypeFull + u['value']
              end
            end
          else
              if (u['value'])
                if is_number?(u['value'])
                  if (u['value'].to_i < 20000)
                    displayContainerTypeFull = displayContainerTypeFull  + u['value']
                  end
                else
                  displayContainerTypeFull = displayContainerTypeFull  + u['value']
                end
              end
          end 
        end
      end
    end

    displayContainerTypeFull = '<div class="container-desc indent-width-' + data['level_num'].to_s + '">' + displayContainerTypeFull + '</div>'

    series_content = (data['level_text'] == 'series' ) ? ' content-series' : ''

    content = '<div class="component-content remainder-width-' + data['level_num'].to_s + series_content + '">'

    if field_values['title']
      series_content = (data['level_text'] != '' ) ? ' content-series' : ''
      content = content + '<div class="title ' + series_content + '">' + field_values['title'] + '</div>' 
    end

    if field_values['date_statement']
      content = content + '<div class="date">&nbsp;' + field_values['date_statement'] + '</div>'
    end

    if field_values['extent_statement']
      content = content + '<div class="extent">&nbsp;' + field_values['extent_statement'] + '</div>'
    end


    fields = ['abstract','controlaccess','bioghist','scopecontent','note','physloc','arrangement','accessrestrict','arrangement','appraisal','langmaterial', 'odd', 'origination']

    fields.each do |f|

      if field_values[f]
        content = content  + '<div class="' + f + '">' + field_values[f] + '</div>'
      end

    end

    content = content + "</div>"


    margin = (data['level_text'] == 'series' || data['level_text'] == 'subseries' ) ? ' margin-' + data['level_text'] : ''

    html =  '<div id="c' + data['id'].to_s + '" class="collection-detailed-row'+ margin +'">'
    
      html = html + displayContainerTypeFull

      html = html + content

    html = html + "</div>"

    html

  end
  
  def is_number?(object)
    true if Float(object) rescue false
  end

end
