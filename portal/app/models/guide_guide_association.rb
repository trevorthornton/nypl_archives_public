class GuideGuideAssociation < ActiveRecord::Base
  attr_accessible :parent_guide_id, :child_guide_id
  
  belongs_to :parent_guide, :class_name => 'Guide'
  belongs_to :child_guide, :class_name => 'Guide'
end
