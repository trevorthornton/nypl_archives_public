module EadUtilityMethods
  
  def access_elements
    access_elements = ['persname','famname','corpname','genreform','geogname','subject','title','occupation']
  end
  
  def name_elements
    name_elements = ['persname','famname','corpname']
  end
  
  def descriptive_identity_elements
    ['unitid','repository','unittitle','unitdate','physdesc','physloc','materialspec','abstract','langmaterial','odd','prefercite']
  end
  
  def context_elements
    ['origination','bioghist','custodhist']
  end

  def content_structure_elements
    ['scopecontent','arrangement']
  end
  
  def acquisition_processing_elements
    ['accruals','acqinfo','separatedmaterial','processinfo','appraisal']
  end
  
  def access_use_elements
    ['container','accessrestrict','userestrict','legalstatus','phystech','altformavail','originalsloc','otherfindaid']
  end
  
  def related_material_elements
    ['relatedmaterial','bibliography']
  end
  
  def description_elements
    elements = descriptive_identity_elements
    elements += context_elements
    elements += content_structure_elements
    elements += acquisition_processing_elements
    elements += access_use_elements
    elements += related_material_elements
  end
  
end