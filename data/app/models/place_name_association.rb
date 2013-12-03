class PlaceNameAssociation < ActiveRecord::Base
  attr_accessible :place_id, :name_association_id
  belongs_to :place, :class_name => "AccessTerm", :conditions => "term_type = 'geogname'", :foreign_key => "place_id"
  belongs_to :name_association, :class_name => "AccessTermAssociation", :foreign_key => "name_association_id"
  has_one :name, :through => :name_association, :class_name => "AccessTerm", :source => :access_term
  
  after_save do
    self.name_association.touch
  end
  
end