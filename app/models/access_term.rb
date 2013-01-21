class AccessTerm < ActiveRecord::Base
  
  attr_accessible :term_original, :term_authorized, :term_type, :authority, :authority_record_id, :value_uri, :authority_control_agent
  
  attr_accessor :name_subject
  
  has_many :access_term_associations, :dependent => :destroy
  has_many :collections, :through => :access_term_associations, :conditions => "describable_type = 'collection'"
  has_many :components, :through => :access_term_associations, :conditions => "describable_type = 'component'"
end
