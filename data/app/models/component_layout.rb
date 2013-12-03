class ComponentLayout < ActiveRecord::Base
  attr_accessible :name, :description
  
  belongs_to :collection
  
end
