class Description < ActiveRecord::Base
  
  include UtilityMethods
  
  attr_accessible :describable_id, :describable_type, :descriptive_identity, :content_structure, :context, :acquisition_processing, :related_material, :access_use
    
  belongs_to :describable, :polymorphic => true
  has_many :collections

end
