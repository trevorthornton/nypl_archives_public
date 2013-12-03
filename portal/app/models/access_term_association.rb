class AccessTermAssociation < ActiveRecord::Base
  
  include ReadOnlyModels
  
  belongs_to :describable, :polymorphic => true
  belongs_to :access_term
end