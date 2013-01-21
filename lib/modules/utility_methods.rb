module UtilityMethods
  
  include ActiveSupport::Inflector
  
  def add_object_attributes_from_descriptive_identity
    desc = JSON.parse(self.description.descriptive_identity)
    self.title = desc['unittitle'][0]['value']
    # Problems with multiple unitid ?
    self.identifier_value = desc['unitid'][0]['value']
    self.identifier_type = desc['unitid'][0]['type']        
  end
  
  
  def access_elements
    access_elements = ['persname','famname','corpname','genreform','geogname','name','subject','title','occupation']
  end
  
  
  def name_elements
    name_elements = ['persname','famname','corpname']
  end
  
  
  def remove_newlines(string)
    string.gsub!(/[\n\r]+\s*/, ' ')
    remove_extra_whitespace(string)
  end
  
  
  def remove_extra_whitespace(string)
    string.gsub!(/[\s]+/, ' ')
    string.gsub!(/\s\<\//, '</')
    string.gsub!(/\s\.\s?$/, '.')
    string.gsub!(/\s\,\s/, ', ')
    string.strip
  end


  def clean_inner_text(text)
    text.strip!
    text.gsub!(/\s{2,}/,' ')
    text.gsub!(/^\(/, '')
    text.gsub!(/\)$/, '')
    remove_newlines(text)
  end
  
  
  # For search index
  
  def common_object_attributes
    object_attributes = [ :id, :title, :identifier_value, :identifier_type, :org_unit_id ]
  end
  
  def collection_attributes
    collection_attributes = common_object_attributes
  end
  
  def component_attributes
    component_attributes = [ :collection_id, :parent_id, :sib_seq, :level_num, :level_text, :has_children ]
    common_object_attributes.concat(component_attributes)
  end
  
  def date_fields_single
    date_fields_single = [ 'date_inclusive_start', 'date_inclusive_end', 'date_bulk_start', 'date_bulk_end' ]
  end
  
  def description_fields
    description_fields = [ 'unittitle', 'unitdate', 'physdesc', 'materialspec', 'abstract',
      'langmaterial', 'prefercite', 'origination', 'bioghist', 'custodhist', 'scopecontent',
      'arrangement', 'accruals', 'acqinfo', 'separatedmaterial', 'processinfo', 'sponsor',
      'appraisal', 'relatedmaterial', 'bibliography', 'physloc', 'accessrestrict', 'userestrict',
      'legalstatus', 'phystech', 'altformavail', 'originalsloc', 'otherfindaid' ]
  end
  
  def date_fields
    date_fields = ['date_bulk_start','date_bulk_end','date_inclusive_start','date_inclusive_end','keydate','dates_index']
  end
  
  # accepts date string in basic ISO 8601, no timte - yyyy(-mm(-dd))
  def date_to_zulu(date_string)
    @@zulu_format = '%Y-%m-%dT12:%M:%SZ'
    date_parts = date_string.split('-')
    date_parts[1] ||= '01'
    date_parts[2] ||= '01'
    date = Date.new(date_parts[0].to_i,date_parts[1].to_i,date_parts[2].to_i)
    date.strftime(@@zulu_format)
  end
  
end