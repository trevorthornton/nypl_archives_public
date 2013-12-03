class CollectionAssociation < ActiveRecord::Base
  
  attr_accessible :describable_id, :describable_type, :collection_id
  
  belongs_to :describable, :polymorphic => true
  belongs_to :collection
  
end