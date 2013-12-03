module DescriptionHelper
  
  include ApplicationHelper
  
  include OrgUnitsHelper
  
  def element_data(element_name,unit_data)
    if simple_elements.include?(element_name)
      standard_element(unit_data,element_name)
    elsif special_elements.include?(element_name)
      send(element_name,unit_data)
    end
  end
  
  
  def standard_element(unit_data, element_name, element_label = nil, property = nil)
    element = element_config(element_name)
    element['label'] = element_label if element_label
    element['property'] = property if property
    if unit_data[element_name].class == String
      element['content'] += unit_data[element_name]
    elsif unit_data[element_name] && unit_data[element_name][0]
      values = []
      unit_data[element_name].each do |a|
        if a['value'] && !a['supress_display']
          values << a['value']
        end
      end
      join_string = structured_elements.include?(element_name) ? "\n" : '; '
      element['content'] += !values.empty? ? values.join(join_string) : ''
      
    end
    element
  end
  
  
  def simple_elements
    elements = ['abstract', 'scopecontent', 'custodhist', 'prefercite', 'arrangement',
      'bioghist', 'acqinfo', 'processinfo', 'separatedmaterial', 'accruals',
      'appraisal', 'container', 'accessrestrict', 'userestrict', 'legalstatus',
      'phystech', 'altformavail',  'originalsloc', 'otherfindaid', 'physloc',
      'langmaterial', 'materialspec', 'odd', 'sponsor', 'org_unit_name', 'bibliography']
  end
  
  def structured_elements
    elements = ['scopecontent', 'custodhist', 'prefercite', 'arrangement',
      'bioghist', 'acqinfo', 'processinfo', 'separatedmaterial', 'accruals',
      'appraisal', 'accessrestrict', 'userestrict', 'legalstatus',
      'phystech', 'altformavail',  'originalsloc', 'otherfindaid', 'physloc', 'odd', 'bibliography']
  end
  
  
  def special_elements
    elements = ['call_number','sponsor','origination','physdesc','physical_location','standard_access_note']
  end


  def element_config(element)
    config = {
      'abstract' => { 'label' => 'Abstract', 'property' => ['schema:description', 'dcterms:abstract'] },
      'accessrestrict' => { 'label' => 'Access restrictions' },
      'accruals' => { 'label' => 'Accruals', 'property' => ['dcterms:accrualMethod'] },
      'acqinfo' => { 'label' => 'Source of acquisition', 'property' => ['dcterms:provenance'] },
      'altformavail' => { 'label' => 'Alternative form available' },
      'appraisal' => { 'label' => 'Appraisal information' },
      'arrangement' => { 'label' => 'Arrangement' },
      'bibliography' => { 'label' => 'Bibliography' },
      'bioghist' => { 'label' => 'Biographical/historical note' },
      'container' => { 'label' => 'Box/folder' },
      'custodhist' => { 'label' => 'Custodial history', 'property' => ['dcterms:provenance'] },
      'langmaterial' => { 'label' => 'Language', 'property' => ['schema:inLanguage'] },
      'legalstatus' => { 'label' => 'Legal status' },
      'materialspec' => { 'label' => 'Material specific details' },
      'odd' => { 'label' => 'Note' },
      'org_unit_name' => { 'label' => 'Repository', 'property' => ['arch:heldBy'] },
      'originalsloc' => { 'label' => 'Location of originals' },
      'origination' => { 'label' => 'Creator', 'property' => ['schema:creator', 'dcterms:creator'] },
      'otherfindaid' => { 'label' => 'Other finding aid' },
      'physdesc' => { 'label' => 'Physical description', 'property' => ['dcterms:extent'] },
      'physical_location' => { 'label' => 'Location', 'property' => ['schema:contentLocation'] },
      'physloc' => { 'label' => 'Location' },
      'phystech' => { 'label' => 'Physical characteristics and technical requirements' },
      'prefercite' => { 'label' => 'Preferred Citation', 'property' => ['dcterms:provenance'] },
      'processinfo' => { 'label' => 'Processing information' },
      'scopecontent' => { 'label' => 'Scope/content', 'property' => ['dcterms:description'] },
      'separatedmaterial' => { 'label' => 'Separated material' },
      'userestrict' => { 'label' => 'Conditions Governing Use' },
      'sponsor' => { 'label' => 'Sponsor' },
      'standard_access_note' => { 'label' => 'Access to materials' }
    }
    config[element]['content'] = ''
    config[element]
  end
  
  
  # move call number to response
  def call_number(unit_data)
    element = {'label' => 'Call number' }
    call_numbers = []
    if unit_data['call_number']
      call_numbers << unit_data['call_number']
    end
    if unit_data['unitid']
      unit_data['unitid'].each do |u|
        if u['type'] == 'local_call'
          call_numbers << u['value']
        end
      end
    end
    call_numbers.uniq!
    element['content'] = !call_numbers.blank? ? call_numbers.join('; ') : ''
    
    if unit_data['bnumber'] && !element['content'].blank?
      link_text = element['content']
      catalog_link = link_to link_text, "http://catalog.nypl.org/record=#{unit_data['bnumber']}",
      { :class => 'catalog-link', :title => 'View catalog record' }
      element['content'] = catalog_link
    end
    
    element
  end
  
  
  def sponsor(unit_data)
    element = element_config('sponsor')
    if unit_data['notes']
      if unit_data['notes']['sponsor']
        element['content'] = unit_data['notes']['sponsor'].join(' ')
      end
    end
    element
  end
  
  
  def origination(unit_data)
    if unit_data['origination_term']
      element = element_config('origination')
      originations = []
      unit_data['origination_term'].each do |t|
        originations << link_to(t['term'], controlaccess_results_path(:access_term_id => t['id'], :term => t['term']))
      end
      element['content'] = originations.join('; ')
      element
    else
      case unit_data['origination']
      when Array
        role = unit_data['origination'][0]['role']
        element_label = role ? role : 'Creator'
        standard_element(unit_data, 'origination', element_label)
      when String
        element = element_config('origination')
        # link_to(t['term'], :controller => 'searches', :action => 'controlaccess', :term_id => t['id'], :term => t['term'])
        element['content'] = unit_data['origination']
        element
      end
    end
  end
  
  
  def physdesc(unit_data)
    if unit_data['extent_statement']
      element = element_config('physdesc')
      element['content'] = unit_data['extent_statement']
      element
    elsif unit_data['physdesc']
      element = element_config('physdesc')
      physdesc_data = unit_data['physdesc'].clone
      if physdesc_data && !physdesc_data.empty?
        physdesc_primary = ''
        physdesc_secondary = []
        physdesc_first = physdesc_data.delete_at(0)
        case physdesc_first['format']
        when 'simple', nil
          physdesc_primary = physdesc_first['value']
        when 'structured'
          physdesc_first['physdesc_components'].each_index do |i|
            if i == 0
              physdesc_primary = physdesc_first['physdesc_components'][i]['value']
            else
              physdesc_secondary << physdesc_first['physdesc_components'][i]['value']
            end
          end
        end
        physdesc_data.each do |p|        
          case p['format']
          when 'simple', nil
            physdesc_secondary << p['value']
          when 'structured'
            p['physdesc_components'].each { |pc| physdesc_secondary << pc['value'] }
          end
        end
        element['content'] += physdesc_primary
        element['content'] += physdesc_secondary.empty? ? '' : " (#{physdesc_secondary.join(';')})"
      end
      element
    end
  end
  
  
  def standard_access_note(unit_data, describable_type = 'collection')
    element = element_config('standard_access_note')
    # element['content'] = unit_data['standard_access_note']
    element['content'] = @org_unit.standard_access_note
    if request_materials_enabled(unit_data['org_unit_code'])
      element['content'] += " "
      link_path = contact_path(:layout => false, :mode => 'request', :collection_id => unit_data['id'], :org_unit_id => unit_data['org_unit_id'])
      element['content'] += link_to "Request access to this collection.", link_path, :class => 'contact-link'
    end
    element
  end
  
  
  def access_restrictions_link
    output = ''
    if @collection_data['accessrestrict'] # || unit_data['userestrict']
      output += '<span class="callout">'
      output += link_to('Restrictions apply', '#access_use', :data => { :toggle => "scrollto" })
      output += '</span>'
    end
    output
  end
  
  
  def physical_location(unit_data)
    element = element_config('physical_location')
    org_unit = OrgUnit.find unit_data['org_unit_id']
    element['content'] = org_unit.name + "<br/>"
    
    center = centers[org_unit.center]
    
    # Schomburg org units include full name of center, so don't include it again
    if !org_unit.name.match(/[Ss]chomburg/)
      element['content'] += center[:name] + "<br/>"
    end
    
    element['content'] += center[:address] + "<br/>"
    if org_unit.location
      element['content'] += org_unit.location
    end
    element
  end
  
  
  # def pdf_finding_aid(unit_data)
  #   pdf = nil
  #   if unit_data['documents']
  #     unit_data['documents'].each do |d|
  #       if d['document_type'] == 'finding aid pdf'
  #         pdf = d
  #         break
  #       end
  #     end
  #   end
  #   pdf
  # end
  
end