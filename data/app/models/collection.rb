class Collection < ActiveRecord::Base
  
  include SharedMethods
  include CollectionDescriptionUpdate
  include ActionView::Helpers::SanitizeHelper
  
  attr_accessible :title, :origination, :identifier_value, :identifier_type, :date_inclusive_start, :date_inclusive_end,
    :date_bulk_start, :date_bulk_end, :bnumber, :call_number, :org_unit_id, :date_statement, :keydate, :active,
    :extent_statement, :linear_feet, :pdf_finding_aid, :boost_queries, :alias, :date_processed, :component_layout_id
  
  mount_uploader :pdf_finding_aid, FileUploader
   
  has_many :components, :dependent => :destroy
  has_many :children, :class_name => "Component", :foreign_key => "collection_id", :conditions => 'level_num = 1', :order => :sib_seq
  
  has_many :collection_associations, :as => :describable, :dependent => :destroy
  has_many :related_collections, :through => :collection_association, :foreign_key => :collection_id
  
  has_one :description, :as => :describable, :dependent => :destroy
  
  belongs_to :org_unit
  
  has_many :ead_ingests, :dependent => :destroy
  has_many :catalog_imports, :dependent => :destroy

  has_many :collection_associations, :as => :describable, :dependent => :destroy
  
  has_many :access_term_associations, :as => :describable, :dependent => :destroy,
    :include => :access_term, :order => "access_terms.term_original ASC"
  
  has_many :nypl_repo_objects, :as => :describable, :dependent => :destroy
  
  has_one :collection_response, :dependent => :destroy
  has_one :component_layout
  
  has_one :amat_record, :dependent => :destroy
  
  has_many :documents, :as => :describable
  has_many :external_resources, :as => :describable

  
  before_destroy do
    self.remove_from_index
  end

  
  after_save do
    self.update_response(:limit => 'desc_data', :skip_components => true)
  end
  
  
  
  
  #############################################################
  # Class methods
  #############################################################
  
  
  def self.find_by_identifier(identifier_value, identifier_type = 'local_mss')
    where(:identifier_value => identifier_value, :identifier_type => identifier_type).first
  end
  
  
  def self.update_responses(options = {})
    find_each { |c| c.update_response(options) }
  end
  
  
  # Create a new collection from an EAD file
  # Required options: :org_unit_id, :filepath (path to EAD file)
  def self.create_from_ead(options)

    required_options = [:filepath, :org_unit_id]
    missing_options = []
    required_options.each { |k| missing_options << k if !options[k] }
    if !missing_options.empty?
      raise "Collection.create_from_ead: The following options are required: #{missing_options.join(',')}."
    else
      attributes = options.clone
      attributes.each_key do |k|
        attributes.delete(k) if !Collection.accessible_attributes.include?(k)
      end
      c = new(attributes)
      c.description = Description.new(:describable_type => 'Collection')
      c.save!
      begin        
        c.update_from_ead(options)
      rescue Exception => e
        logger.error e
        c.destroy
        ActiveRecord::Base.connection.execute('ALTER TABLE collections AUTO_INCREMENT = 1')
        ActiveRecord::Base.connection.execute('ALTER TABLE descriptions AUTO_INCREMENT = 1')
        raise e
      end

      #remove the EAD file from the temp dir if it was a
      if options[:tmp_file]
        begin 
          open(options[:delete_url])  
        rescue Exception => e
          puts "Error deleteing ead"
        end
      end

    end



  end
  
  
  def self.create_from_catalog_record(options)
    required_options = [:bnumber, :org_unit_id]
    missing_options = []
    required_options.each { |k| missing_options << k if !options[k] }
    if !missing_options.empty?
      raise "Collection.create_from_catalog_record: The following options are required: #{missing_options.join(',')}."
    else
      existing = Collection.where(:bnumber => options[:bnumber]).first
      if existing
        c = existing
      else
        attributes = options.clone
        attributes.each_key do |k|
          attributes.delete(k) if !Collection.accessible_attributes.include?(k)
        end
        c = new(attributes)
        c.description = Description.new(:describable_type => 'Collection')
        c.save!
      end
      c.update_from_catalog_record(options)
    end
  end
  
  
  def self.reset_auto_increment
    # RESET AUTO INCREMENTS
    ActiveRecord::Base.connection.execute('ALTER TABLE collections AUTO_INCREMENT = 1')
    ActiveRecord::Base.connection.execute('ALTER TABLE components AUTO_INCREMENT = 1')
    ActiveRecord::Base.connection.execute('ALTER TABLE descriptions AUTO_INCREMENT = 1')
    ActiveRecord::Base.connection.execute('ALTER TABLE access_term_associations AUTO_INCREMENT = 1')
    ActiveRecord::Base.connection.execute('ALTER TABLE access_terms AUTO_INCREMENT = 1')
    # ActiveRecord::Base.connection.execute('ALTER TABLE amat_records AUTO_INCREMENT = 1')
  end
  
  
  
  
  #############################################################
  # Instance methods
  #############################################################
  
  
  
  
  #############################################################
  # Retrieval & calculation methods
  #############################################################
  
  def response
    self.collection_response
  end
  
  
  # Generates persistent public URL for collection
  def persistent_path
    if self.identifier_value && self.org_unit
      "/#{self.org_unit.code.downcase}/#{self.identifier_value}"
    else
      "/collection/#{self.id}"
    end
  end


  def related_collections
    self.collections
  end
  
  
  def last_ead_ingest
    self.ead_ingests.order('created_at asc').last
  end
  
  
  def last_catalog_import
    self.catalog_imports.order('created_at asc').last
  end

  
  def max_component_level
    max_level_sql = "select max(level_num) as max_depth from components where collection_id=#{self.id.to_s}"
    Collection.find_by_sql(max_level_sql).first['max_depth']
  end
  
  
  def num_components
    Component.where(:collection_id => self.id).count
  end
  
  
  def num_series
    Component.where(:collection_id => self.id, :parent_id => nil).count
  end
  
  
  def series
    series = []
    Component.where(:collection_id => self.id, :level_num => 1, :level_text => 'series').order(:sib_seq).each do |s|
      series << s
    end
    series
  end
  
  
  def structure(options={})
    
    # max_level = options[:max_level] || 'subseries'
    tree = { :id => self.id, :type => self.class.to_s,
      :title => self.title, :total_children => self.children.length, :total_components => self.components.length}
    
    add_children = Proc.new do |object, hash|
      
      object_children = object.children.where("level_text IN ('series','subseries')")
      
      if !object_children.empty?
        object_children.each do |c|
          child_hash = c.unit_data
          child_hash[:total_children] = c.children.length
          child_hash[:total_components] = c.descendants.length
          add_children.call(c,child_hash)
          (hash[:components] ||= []) << child_hash
        end
      end
    end
    if self.series_count && self.series_count > 0
      add_children.call(self, tree)
    end
    tree
  end
  
  
  def total_nypl_repo_objects
    sql = "select count(n.id) as count from nypl_repo_objects n
      join components cc on n.describable_id = cc.id
      join collections c on c.id = cc.collection_id
      where n.describable_type = 'Component'
      and n.total_captures > 0
      and c.id = #{self.id}"
    connection = ActiveRecord::Base.connection
    results = ActiveRecord::Base.connection.execute(sql)
    results.first[0]
  end
  
  
  # returns JSON representation of collection structure for use by MMS collection import
  def mms_json(root_url)
    add_children = Proc.new do |parent_hash, children|
      children.each do |c|
        child = { :mods_url => "#{root_url}/components/#{c.id}/mods" }
        if !c.children.empty?
          add_children.call(child, c.children)
        end
        if c.level_text == 'item'
          (parent_hash[:items] ||= []) << child
        else
          (parent_hash[:containers] ||= []) << child
        end
      end
    end
    
    data = { :mods_url => "#{root_url}/collections/#{self.id}/mods", :org_unit_code => self.org_unit.code }
    
    if !self.children.empty?
      add_children.call(data,self.children)
    end
    
    JSON.generate(data)
  end
  
  
  #############################################################
  # Update methods
  #############################################################
  
  def update_max_depth
    max_depth = self.max_component_level
    if max_depth
      self.update_attribute(:max_depth, max_depth)
    end
  end


  def update_series_count
    series = self.series
    if series
      if series.length == self.children.length
        self.update_attribute(:series_count, series.length)
      else
        puts "Collection #{self.id} - top components include mixed levels"
      end
    end
  end
  
  
  def update_hierarchy_attributes
    begin
      self.update_series_count
      self.update_max_depth
    rescue Exception => e
      puts e
      sleep 1.0
    end
  end


  def update_response(options={})
    require 'json'
    self.collection_response ||= CollectionResponse.new
    
    if !options[:limit] || options[:limit] == 'desc_data'
      data = self.unit_data
      access_terms = self.access_term_data(:controlaccess => true)
      
      self.origination_associations.each do |o|
        (data['origination_term'] ||= []) << o.term_hash
      end
      
      # limiting to term assications with control_access == true
      #   see filter_controlaccess in protected methods below
      data['controlaccess'] = filter_controlaccess(access_terms)
      data['max_depth'] = self.max_component_level 
      data['total_children'] = self.children.length
      data['total_components'] = self.components.length
      
      # Update finding aid with URL
      if !self.pdf_finding_aid.blank?
        data['pdf_finding_aid_url'] = self.pdf_finding_aid_url
      end
      
      data['resources'] = self.resource_data
      
      # digitized content (nypl_repo_objects association)
      if self.total_nypl_repo_objects > 0
        data['digital_assets'] = true
      end
      
      # remove elements with internal:true
      data.each do |k,v|
        if v.kind_of? Array
          v.each do |e|
            if e.kind_of? Hash
              if e['internal'] || e['audience'] == 'internal'
                v.delete(e)
              end
            end
          end
        end
      end
      
      compact(data)
      
      self.collection_response.desc_data = JSON.generate(data)
    end
    
    if !options[:limit] || options[:limit] == 'structure'
      self.collection_response.structure = JSON.generate(self.structure)
    end
    
    if !options[:skip_components]
      Component.find_each(:conditions => "collection_id = #{self.id}") { |c| c.update_response(options) }
    end
    
    self.collection_response.save
  end
  
  
  def update_from_catalog_record(options={})
    if self.bnumber
      import = CatalogImport.new(:collection_id => self.id, :bnumber => self.bnumber)
      begin
        import.execute
        puts "Catalog record imported successfully. CatalogIngest id = #{import.id}. Collection id = #{self.id}"
        self.reload
        self.update_response
      rescue Exception => e
        puts "Catalog import failed :("
        puts e
      end
    end
  end
  
  
  # Import data from EAD file, updating existing data where present
  # Required options: :filepath (path to EAD file)
  def update_from_ead(options={})
    
    # Permitted values for options[:update_type] (verified in EadIngest):
    #    'all' (update collection-level data and all components)
    #    'collection' (update collection-level data only)
    #    'components' (update components only)
    update_type = options[:update_type] || 'all'
    
    if !options[:filepath]
      raise "Collection#update_from_ead: The following options are required: #{missing_options.join(',')}."
    else
      message = "Beginning ingest of Collection #{self.id.to_s} from EAD..."
      logger.info message
      i = EadIngest.new(:collection_id => self.id, :update_type => update_type,
        :filename => options[:filepath].split('/').last)
      i.filepath = options[:filepath]

      begin
        i.execute
        # update/create collection_response after ingest completes
        skip_components = (options[:update_type] == 'collection') ? true : false
        limit = (options[:update_type] == 'collection') ? 'desc_data' : nil
        self.reload
        self.update_response(:skip_components => skip_components, :limit => limit)
      rescue Exception => e
        logger.error e
        raise e
      end
    end
  end


  def post_ingest_updates(options={})
    data = self.description_data
    
    self.update_title_and_origination(data)
    self.remove_date_from_title(data)
    self.update_date_statement(data)
    self.update_extent_statement(data)
    self.add_call_number_from_description(data)
    self.update_keydate(data)
    self.generate_prefercite(data)
    self.enhance_description(data)
    self.remove_standard_accessrestrict(data)
    self.remove_findingaid_reference(data)
    
    self.update_hierarchy_attributes

    if !options[:skip_components]
      Component.find_each(:conditions => "collection_id = #{self.id}") do |c|
        c.update_hierarchy_attributes
        c.update_description_attributes
      end
      self.update_component_load_seq
    end
    
  end
  
  
  def update_nypl_repo_object_captures
    self.components.each.each do |c|
      c.update_nypl_repo_object_captures
    end
  end
  
  
  def update_title_and_origination(data = nil)
    if self.description
      data ||= self.description_data
      if data
        if !data['unittitle'].blank?
          title = data['unittitle'][0]['value']
          self.update_attributes(:title => title)
        end
        
        if !data['origination'].blank?
          origination = data['origination'][0]['value']
          self.update_attributes(:origination => origination)
        end
      end
    end
  end
  
  
  # add call_number to collection record from either unitid or physloc
  # first value present will be used
  def add_call_number_from_description(data=nil)
    if self.call_number.blank?
      data ||= self.description_data
      call_number = nil
      if data['unitid']
        puts data['unitid'].inspect
        data['unitid'].each do |u|
          if u['type'] == 'local_call'
            call_number = u['value']
            u['supress_display'] = true
            break
          end
        end
      end
      
      if !call_number && data['physloc']
        puts data['physloc'].inspect
        data['physloc'].each do |p|
          if p['type'] == 'local_call'
            call_number = p['value']
            p['supress_display'] = true
            break
          end
        end
      end
      
      if call_number
        self.update_attributes(:call_number => call_number)
        self.description.update_data(data)
        return [self.id, call_number]
      else
        nil
      end
    end
  end

  
  def update_keydate(data = nil)
    data ||= self.description_data
    if data['keydate']
      keydate_string = data['keydate'].to_s
      if keydate_string.match(/^\d{4}$/)
        keydate = keydate_string.to_i
      elsif keydate_string.match(/\d{4}/)
        keydate = keydate_string.scan(/\d{4}/)[0]
      else
        keydate = nil
      end
    else
      keydate = nil
    end
    self.update_attributes(:keydate => keydate)
  end  
  
  
  def update_component_load_seq
    @i = 0
    
    update_load_seq = Proc.new do |component|
      @i += 1
      component.update_attributes(:load_seq => @i)
      component.children.each do |cc|
        update_load_seq.call(cc)
      end
    end
    
    self.children.each do |c|
      update_load_seq.call(c)
    end
  end
  
  
  def update_index(options={})
    i = SearchIndex.new
    i.update_collection_in_index(self.id,options)
  end
  
  
  def remove_from_index
    i = SearchIndex.new
    i.delete_collection_from_index(self.id)
  end

  
  protected
  
  
  
  
end