class Description < ActiveRecord::Base
  
  include ReadOnlyModels
  
  belongs_to :describable, :polymorphic => true
  
end