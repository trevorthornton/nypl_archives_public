class CollectionResponse < ActiveRecord::Base
  
  include ReadOnlyModels
  
  belongs_to :collection
  
end
