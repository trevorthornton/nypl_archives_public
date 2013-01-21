class Collection < ActiveRecord::Base
  
  include SharedMethods
  
  attr_accessible :title, :identifier_value, :identifier_type, :date_inclusive_start, :date_inclusive_end, :date_bulk_start, :date_bulk_end,
    :linear_feet, :items, :nypl_repo_uuid, :org_unit_id, :catalog_url, :date_statement, :keydate, :active
    
  has_many :components, :dependent => :destroy
  has_many :children, :class_name => "Component", :foreign_key => "collection_id", :conditions => 'level_num = 1', :order => :sib_seq
  
  has_one :description, :as => :describable, :dependent => :destroy
  belongs_to :org_unit
  belongs_to :ead_ingest

  has_many :collection_associations, :as => :describable, :dependent => :destroy
  
  has_many :access_term_associations, :as => :describable, :dependent => :destroy
    
  after_destroy do
    self.reset_auto_increment
  end
  
  def related_collections
    self.collections
  end
  
  
  def reset_auto_increment
    # RESET AUTO INCREMENTS
    ActiveRecord::Base.connection.execute('ALTER TABLE collections AUTO_INCREMENT = 1')
    ActiveRecord::Base.connection.execute('ALTER TABLE components AUTO_INCREMENT = 1')
    ActiveRecord::Base.connection.execute('ALTER TABLE descriptions AUTO_INCREMENT = 1')
    ActiveRecord::Base.connection.execute('ALTER TABLE access_term_associations AUTO_INCREMENT = 1')
  end

  
  def max_component_level
    max_level_sql = "select max(level_num) as max_levels from components where collection_id=#{self.id.to_s}"
    Collection.find_by_sql("select max(level_num) as max_levels from components where collection_id=#{self.id.to_s}").first['max_levels']
  end
  
  
  def num_components
    Component.where(:collection_id => self.id).count
  end
  
  
  def num_series
    Component.where(:collection_id => self.id, :parent_id => nil).count
  end
  
  
  def series
    series = {}
    Component.where(:collection_id => self.id, :level_num => 1).each do |s|
      series[s.id] = {}
      series[s.id]['title'] = s.title
      series[s.id]['identifier_value'] = s.identifier_value
      series[s.id]['identifier_type'] = s.identifier_type
    end
    series
  end
  
  
  def update_origination
    context = JSON.parse(self.description.context)
    origination = context['origination'][0]['value']
    self.update_attribute(:origination, origination)
  end
  
  
  def structure(options={})
    max_level = options[:max_level] || 'subseries'
    components = Component.where(:collection_id => self.id).order(:sib_seq)
    tree = {:id => self.id, :type => self.class.to_s, :title => self.title}
    
    add_children = Proc.new do |component_hash|
      if max_level == 'subseries'
        children = components.where("parent_id = #{component_hash[:id]} AND level_text IN ('series','subseries')")
      else
        children = components.where(:parent_id => component_hash[:id])
      end
      
      if children
        children.each do |c|
          child_hash = c.basic_unit_data
          if c.has_children || ['series','subseries'].include?(c.level_text)
            component_hash[:components] ||= []
            component_hash[:components] << child_hash
            add_children.call(child_hash)
          else
            if options[:include_leaves]
              component_hash[:components] ||= []
              component_hash[:components] << child_hash
            end
          end
        end
      end
    end
    
    series = components.where(:level_num => 1)
    
    if series
      tree[:components] = []
      series.each do |s|
        series_hash = s.basic_unit_data
        if s.has_children
          add_children.call(series_hash)
        end
        tree[:components] << series_hash
      end
    end
    
    return tree
  end
  
  
  def post_ingest_updates(options={})
    self.update_origination
    self.update_date_statement
    self.update_keydate
    if !options[:skip_components]
      components = self.components
      components.each do |c|
        c.update_has_children
        c.update_max_levels
        c.update_top_component_id
      end
    end
  end
  
  
  def update_date_statement
    descriptive_identity = JSON.parse(self.description.descriptive_identity)
    if descriptive_identity['unitdate']
      dates = {}
      descriptive_identity["unitdate"].each do |d|
        if d['type']
          dates[d['type']] = d['value']
        else
          dates['other'] = d['value']
        end
      end
      if (dates['inclusive'] || dates['other']) && dates['bulk']
        self.date_statement = "#{dates['inclusive'] || dates['other']} [bulk #{dates['bulk']}]"
      elsif (dates['inclusive'] || dates['other']) && !dates['bulk']
        self.date_statement = "#{dates['inclusive'] || dates['other']}"
      elsif dates['bulk']
        self.date_statement = "bulk #{dates['bulk']}"
      end
    else
      self.date_statement = nil
    end
    self.save
  end
  
  
  def update_keydate
    descriptive_identity = JSON.parse(self.description.descriptive_identity)
    if descriptive_identity['keydate']
      keydate_string = descriptive_identity['keydate']
      if keydate_string.match(/^\d{4}$/)
        self.keydate = keydate_string.to_i
      elsif keydate_string.match(/\d{4}/)
        self.keydate = keydate_string.scan(/\d{4}/)[0]
      else
        self.keydate = nil
      end
    else
      self.keydate = nil
    end
    self.save
  end
  
  
end