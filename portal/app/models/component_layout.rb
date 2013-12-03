class ComponentLayout < ActiveRecord::Base
  # attr_accessible :title, :body
  
  belongs_to :collection
  
end
