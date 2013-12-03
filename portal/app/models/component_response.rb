class ComponentResponse < ActiveRecord::Base
  
  include ReadOnlyModels
  
  belongs_to :component
  
end
