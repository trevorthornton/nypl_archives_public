class Component < ActiveRecord::Base
  
  include ReadOnlyModels
  
  belongs_to :collection
  
  belongs_to :parent_component, :class_name => "Component", :foreign_key => "parent_id"
  has_many :children, :class_name => "Component", :foreign_key => "parent_id", :order => 'sib_seq ASC, created_at ASC'
  
  has_one :description, :as => :describable
  has_many :access_term_associations, :as => :describable
  
  has_one :component_response, :class_name => "ComponentResponse", :foreign_key => "component_id"
  
  has_many :record_guide_associations, :as => :describable
  has_many :guides, :through => :record_guide_associations, :conditions => "describable_type = 'Component'"
  
  def response
    self.component_response
  end
  
end
