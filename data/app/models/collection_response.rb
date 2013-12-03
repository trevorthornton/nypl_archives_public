class CollectionResponse < ActiveRecord::Base
  attr_accessible :collection_id, :desc_data, :structure
  belongs_to :collection
end
