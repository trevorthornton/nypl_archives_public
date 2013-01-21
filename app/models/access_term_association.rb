class AccessTermAssociation < ActiveRecord::Base
  
  attr_accessible :describable_id, :describable_type, :access_term_id, :controlaccess, :role
  
  belongs_to :describable, :polymorphic => true
  belongs_to :access_term
  
end