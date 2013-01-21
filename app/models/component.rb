class Component < ActiveRecord::Base
  
  include SharedMethods
  
  has_one :description, :as => :describable, :dependent => :destroy
  
  belongs_to :collection
  belongs_to :org_unit
  
  belongs_to :parent_component, :class_name => "Component", :foreign_key => "parent_id"
  has_many :children, :class_name => "Component", :foreign_key => "parent_id", :order => :sib_seq
    
  has_many :access_term_associations, :as => :describable, :dependent => :destroy  
  
  def self.reset_auto_increment
    # RESET AUTO INCREMENTS
    ActiveRecord::Base.connection.execute('ALTER TABLE components AUTO_INCREMENT = 1')
    ActiveRecord::Base.connection.execute('ALTER TABLE descriptions AUTO_INCREMENT = 1')
    ActiveRecord::Base.connection.execute('ALTER TABLE access_term_associations AUTO_INCREMENT = 1')
  end
  
  def update_has_children
    children = Component.where(:parent_id => self.id)
    has_children = children.empty? ? false : true
    self.update_attribute(:has_children, has_children)
  end
  
  
  def update_max_levels
    levels = 0
    
    increment_levels = Proc.new do |cc|
      test_children = []
      cc.each do |c|
        test_children << c if c.has_children
      end
      if !test_children.blank?
        levels += 1
        grandchildren = []
        test_children.each do |tc|
          tc.children.each { |gc| grandchildren << gc }
        end
        increment_levels.call(grandchildren)
      end
    end
    
    if self.has_children
      levels += 1
      increment_levels.call(self.children)
    end
    
    self.update_attribute(:max_levels, levels)
  end
  
  
  def update_top_component_id
    ancestors = self.component_ancestors
    if !ancestors.blank?
      self.update_attribute(:top_component_id, ancestors.first.id)
    end
  end


  # retruns array of all anscestor components, in ascending order by level
  def component_ancestors
    ancestors = []
    add_parent = Proc.new do |component|
      if component.parent_id
        parent = Component.find component.parent_id
        ancestors << parent
        add_parent.call(parent) if parent.parent_id
      end
    end
    add_parent.call(self)
    ancestors.reverse
  end
  
  
end
