class Guide < ActiveRecord::Base
  attr_accessible :title, :description, :url_token, :user_id
  
  has_many :record_guide_associations, :dependent => :destroy
  has_many :collections, :through => :record_guide_associations, :source => :describable, :source_type => 'Collection'
  has_many :components, :through => :record_guide_associations, :source => :describable, :source_type => 'Component'
  
  has_many :guide_guide_associations, :foreign_key => 'parent_guide_id', :dependent => :destroy
  has_many :parent_guides, :through => :guide_guide_associations, :class_name => 'Guide', :foreign_key => 'child_guide_id'
  has_many :child_guides, :through => :guide_guide_associations, :class_name => 'Guide', :foreign_key => 'child_guide_id'
end
