class Collection < ActiveRecord::Base
  
  include ReadOnlyModels
  include EadExport
  include PdfExport
  
  mount_uploader :pdf_finding_aid, FileUploader
  
  has_one :collection_response
  has_one :description, :as => :describable
  has_one :component_layout
  has_many :access_term_associations, :as => :describable
  belongs_to :org_unit
  
  has_many :components
  has_many :children, :class_name => "Component", :foreign_key => "collection_id", :conditions => 'level_num = 1', :order => :sib_seq
  
  has_many :record_guide_associations, :as => :describable
  has_many :guides, :through => :record_guide_associations, :conditions => "describable_type = 'Collection'"
  
  def response
    self.collection_response
  end
  
  # Generate EAD XML for collection
  def ead
    e = EadRecord.new(:collection_id => self.id)
    e.generate
  end

  # Generate PDF
  def pdf
    e = PdfFile.new(:collection_id => self.id, :nocache => false)
    return e.return_path()
    #e.generate
  end

  # Generate PDF
  def pdf_recreate
    e = PdfFile.new(:collection_id => self.id, :nocache => true)
    return e.return_path()
    #e.generate
  end
  
  # Generates persistent public URL for collection
  def persistent_path
    if self.identifier_value && self.org_unit
      "/#{self.org_unit.code.downcase}/#{self.identifier_value}"
    else
      "/collection/#{self.id}"
    end
  end
  
end