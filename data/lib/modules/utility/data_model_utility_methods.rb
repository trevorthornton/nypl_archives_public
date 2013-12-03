module DataModelUtilityMethods
  
  def common_object_attributes
    object_attributes = [ :id, :title, :origination, :identifier_value, :identifier_type,
      :org_unit_id, :date_statement, :extent_statement, :linear_feet ]
  end
  
  def collection_attributes
    collection_attributes = common_object_attributes
    collection_attributes += [ :bnumber, :call_number]
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
  
  
end