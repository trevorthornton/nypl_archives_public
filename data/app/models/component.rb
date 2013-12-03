class Component < ActiveRecord::Base
  
  include SharedMethods
  
  has_one :description, :as => :describable, :dependent => :destroy
  
  belongs_to :collection
  
  belongs_to :parent_component, :class_name => "Component", :foreign_key => "parent_id"
  has_many :children, :class_name => "Component", :foreign_key => "parent_id", :order => 'sib_seq ASC, created_at ASC'
    
  has_many :access_term_associations, :as => :describable, :dependent => :destroy
  # has_many :access_terms, :through => :access_term_associations
  
  has_many :nypl_repo_objects, :as => :describable, :dependent => :destroy, :order => 'sib_seq ASC, created_at ASC'
  
  has_one :component_response, :dependent => :destroy
  
  has_many :documents, :as => :describable
  has_many :external_resources, :as => :describable
  
  attr_accessible :identifier_value, :identifier_type, :title, :parent_id, :sib_seq, :has_children,
    :level_num, :level_text, :top_component_id, :max_depth, :org_unit_id, :origination,
    :date_statement, :extent_statement, :linear_feet, :collection_id, :load_seq, :boost_queries
  
  before_destroy do 
    self.remove_from_index
    self.collection.touch
  end
  
  after_save do
    self.collection.touch
  end



  #############################################################
  # Retrieval & calculation methods
  #############################################################
  
  def org_unit
    self.collection.org_unit
  end
  
  
  def response
    self.component_response
  end
  
  
  def total_nypl_repo_objects
    self.nypl_repo_objects.length
  end
  
  
  def descendants
    descendant_set = []
    add_children = Proc.new do |component|
      component.children.each do |c|
        descendant_set << c
        add_children.call(c)
      end
    end
    add_children.call(self)
    descendant_set
  end
  
  
  # returns an array of child components (including id and title for each)
  # and a nested array of children of each where they exist
  def structure
    add_children = Proc.new do |component,array|
      component.children.each do |c|
        child_hash = { :id => c.id, :title => c.title, :children => [] }
        add_children.call(c, child_hash[:children])
        array << child_hash
      end
    end
    structure_data = {:id => self.id, :title => self.title, :children => []}
    add_children.call(self, structure_data[:children])
    structure_data
  end
  
  
  # returns array of all anscestor components, in ascending order by level
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
  
  
  # Generates persistent public URL for component
  def persistent_path
    path = self.collection.persistent_path
    path += "#c#{self.id}"
  end
  
  
  
  #############################################################
  # Update methods
  #############################################################
  
  def update_description_attributes
    data = self.description_data
    self.update_title_and_origination(data)
    self.update_date_statement(data)
    self.update_extent_statement(data)
  end
  
  
  def update_hierarchy_attributes
    self.update_has_children
    self.update_max_depth
    self.update_top_component_id
  end
  
  
  def update_has_children
    children = Component.where(:parent_id => self.id)
    has_children = children.empty? ? false : true
    self.update_attribute(:has_children, has_children)
  end
  
  
  def update_max_depth
    depth = 0
    increment_levels = Proc.new do |cc|
      test_children = []
      cc.each do |c|
        test_children << c if c.has_children
      end
      if !test_children.blank?
        depth += 1
        grandchildren = []
        test_children.each do |tc|
          tc.children.each { |gc| grandchildren << gc }
        end
        increment_levels.call(grandchildren)
      end
    end
    if self.has_children
      depth += 1
      increment_levels.call(self.children)
    end
    self.update_attribute(:max_depth, depth)
  end
  
  
  def update_top_component_id
    ancestors = self.component_ancestors
    if !ancestors.blank?
      self.update_attribute(:top_component_id, ancestors.first.id)
    end
  end
  
  
  def update_response(options={})
    require 'json'
    self.component_response ||= ComponentResponse.new
    
    if !options[:limit] || options[:limit] == 'desc_data'
      data = self.unit_data
      data[:controlaccess] = self.access_term_data(:controlaccess => true)      
      
      data[:total_children] = self.children.length
      data[:total_components] = self.descendants.length
      if data[:total_children] > 0
        data[:child_ids] = []
        self.children.each { |c| data[:child_ids] << c.id }
      end
      
      data[:origination_place] = self.origination_place
      
      data[:physdesc_note] =  self.physdesc_note
      
      compact(data)
      self.component_response.desc_data = JSON.generate(data)
    end
    if !options[:limit] || options[:limit] == 'structure'
      self.component_response.structure =
        self.structure ? JSON.generate(self.structure) : nil
    end
    if !options[:limit] || options[:limit] == 'digital_objects'
      self.component_response.digital_objects =
        self.all_digital_objects ? JSON.generate(self.all_digital_objects) : nil
    end
    self.component_response.save
  end
  
  
  def update_nypl_repo_object_captures
    self.nypl_repo_objects.each do |o|
      o.update_captures
    end
    self.update_response
  end
  

  def reset_child_sib_seq
    children = self.children
    total_children = children.length
    sib_seq_values = (1..total_children).to_a
    children.each do |c|
      index = children.index(c)
      c.update_attribute(:sib_seq, sib_seq_values[index])
    end
  end
  
  
  def update_index
    i = SearchIndex.new
    i.update_component_in_index(self.id)
  end
  
  
  def remove_from_index
    i = SearchIndex.new
    i.delete_component_from_index(self.id)
  end
  
end