class ComponentResponse < ActiveRecord::Base
  attr_accessible :component_id, :desc_data, :structure
  belongs_to :component
end
