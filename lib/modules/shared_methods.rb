module SharedMethods
  # These methods are shared between the Collection and Component models
  
  include UtilityMethods

  def access_terms
    access_terms = []
    self.access_term_associations.each do |a|
      term = AccessTerm.find a.access_term_id
      term.name_subject = a.name_subject
      access_terms << term
    end
    access_terms
  end
  
  
  def basic_unit_data(options = {})
    data = {}
    self.class.column_names.each { |a| data[a.to_sym] = self[a] }
    data[:type] = self.class.to_s
    return data
  end
  
  
  def unit_data(options={})
    unit_data = self.basic_unit_data
    
    element_groups = []
    
    if !options[:basic]
      description = self.description
      if description.descriptive_identity
        descriptive_identity = JSON.parse(description.descriptive_identity)
        if !options[:index]
          descriptive_identity.delete('dates_index')
        end
        element_groups << descriptive_identity
      end
      element_groups << JSON.parse(description.context) if description.context
      element_groups << JSON.parse(description.content_structure) if description.content_structure
      element_groups << JSON.parse(description.access_use) if description.access_use
      element_groups << JSON.parse(description.acquisition_processing) if description.acquisition_processing
      element_groups << JSON.parse(description.related_material) if description.related_material
      element_groups.each { |g| unit_data.merge!(g) }
      # add notes
      unit_data[:notes] = JSON.parse(description.notes) if description.notes
    end
    
    unit_data 
  end
  
  
  def access_term_data
    access_terms = {}
    self.access_terms.each do |t|
      term_text = t.term_authorized ? t.term_authorized : t.term_original
      term_hash = { :id => t.id, :term => term_text }
      if name_elements.include?(t.term_type)
        if t.name_subject
          access_terms['subject'] ||= []
          access_terms['subject'] << term_hash
        else
          access_terms['name'] ||= []
          access_terms['name'] << term_hash
        end
      elsif t.term_type == 'genreform'
        access_terms['genreform'] ||= []
        access_terms['genreform'] << term_hash
      else
        access_terms['subject'] ||= []
        access_terms['subject'] << term_hash
      end
    end
    access_terms
  end
    
  
  def child_component_data
    children = self.children
    child_component_data = []
    children.each do |c|
      data = c.unit_data
      data[:access_terms] = c.access_term_data
      data[:child_id] = []
      c.children.each { |cc| data[:child_id] << cc.id }
      data.delete_if { |k,v| v.blank? }
      child_component_data << data
    end
    child_component_data
  end
  
  
  def all_component_data(level=nil)
    case self
    when Collection
      relation = Component.includes(:description,:access_term_associations).where(:collection_id => self.id)
      parent_id = nil
    when Component
      child_level = self.level_num + 1
      relation = Component.includes(:description,:access_term_associations).where(:collection_id => self.collection_id).where("level_num > #{self.level_num}")
      parent_id = self.id
    end
    i = 1
    
    get_child_component_data = lambda do |parent_id|
      
      children = relation.where(:parent_id => parent_id)
      if !children.empty?
        component_data = []
        children.each do |c|
          data = c.unit_data
          data[:access_terms] = c.access_term_data
          if c.has_children
            if level.nil? || level > i
              i += 1
              data[:components] = get_child_component_data.call(c.id)
            else
              data[:child_id] = []
              c.children.each { |cc| data[:child_id] << cc.id }
            end
          end

          if !c.has_children
            data[:image_count] = c.total_captures
          end
          
          data.delete_if { |k,v| v.blank? }
          component_data << data 
        end
        return component_data
      else
        return nil
      end
    end
    
    return get_child_component_data.call(parent_id)
    
  end
    
  
  ### Convenience methods to extract elements of description ###
  def abstract
    description = JSON.parse(self.description.descriptive_identity)
    abstract = description['abstract'] ? description['abstract'][0]['value'] : nil
  end

  def prefercite
    description = JSON.parse(self.description.descriptive_identity)
    prefercite = description['prefercite'] ? description['prefercite'][0]['value'].gsub!(/\<[^\>]*\>/,'').strip : nil
  end
  
   

  ### Search index methods ###

  def solr_doc_hash
    @doc = {}
    case self
    when Collection
      object_attributes = collection_attributes
    when Component
      object_attributes = component_attributes
    end
    object_attributes.each do |a|
      attribute_value = self.send(a)
      if attribute_value
        @doc[a] = attribute_value
      end
    end
    @doc[:type] = self.class.to_s.downcase
    self.generate_solr_unique_id
    self.generate_solr_association_fields
    self.generate_solr_component_path if self.class == Component
    self.generate_solr_access_fields
    self.generate_solr_date_fields
    self.generate_solr_description_fields
    self.copy_facet_fields
    @doc
  end
  
  
  def unique_id
    "#{self.class.to_s.downcase}_#{self.id.to_s}"
  end
  
  def generate_solr_unique_id
    if defined?(@doc)
      @doc[:unique_id] = self.unique_id
    end
  end
  
  
  def generate_solr_association_fields
    if defined?(@doc)
      @doc[:org_unit_name] = self.org_unit.name
      if self.class == Component
        @doc[:collection_title] = self.collection.title
        if self.parent_component
          @doc[:parent_title] = self.parent_component.title
        end
      end
    end
  end

  
  # returns array of all anscestor component titles, in ascending order by level
  def generate_solr_component_path
    if defined?(@doc)
      component_path = []
      self.component_ancestors.each { |a| component_path << a.title }
      @doc[:component_path] = component_path
    end
  end
  
  
  def generate_solr_access_fields
    if defined?(@doc)
      self.access_term_associations.each do |a|
        @doc[:access_terms] ||= []
        term = a.access_term.term_authorized ? a.access_term.term_authorized : a.access_term.term_original
        @doc[:access_terms] << term
        case a.access_term.term_type
        when 'persname','corpname','famname','name'
          @doc[:access_name] ||= []
          @doc[:access_name] << term
        when 'genreform'
          @doc[:access_genreform] ||= []
          @doc[:access_genreform] << term
        when 'geogname'
          @doc[:access_geogname] ||= []
          @doc[:access_geogname] << term
        when 'subject'
          @doc[:access_subject] ||= []
          @doc[:access_subject] << term
        when 'title'
          @doc[:access_title] ||= []
          @doc[:access_title] << term
        when 'occupation'
          @doc[:access_occupation] ||= []
          @doc[:access_occupation] << term
        end
      end
    end
  end
  
  
  # call on instance of Description
  # will return nil if called outside the context of genrating a has of values passed in a solr update request
  def generate_solr_date_fields
    if defined?(@doc)
      data = JSON.parse(self.description.descriptive_identity)
      puts 'generate_solr_date_fields'
      puts date_fields.inspect
      date_fields.each do |f|
        if data[f]
          if f == 'keydate'
            @doc[:keydate] = date_to_zulu(data[f])
          else
            @doc[f.to_sym] = data[f]
          end
          
          if f == 'dates_index'
            decades = []
            data[f].each do |d|
              decade = d - (d % 10)
              if !decades.include?(decade)
                decades << decade
              end
            end
            @doc[:dates_decade] = decades if !decades.blank?
          end
        end

      end      
    end
  end
  
  
  # search index methods
  
  def generate_solr_description_fields
    if defined?(@doc)
      puts 'generate_solr_description_fields'
      description_attributes = [:descriptive_identity,:context,:content_structure,:acquisition_processing,:related_material,:access_use]
      description_attributes.each do |a|
        field_group = self.description.send(a)
        if !field_group.blank?
          data = JSON.parse(field_group)
          data.each do |k,v|
            if date_fields.include?(k)
              next
            elsif k == 'container'
              v.each do |c|
                doc_key = c['type'] ? "container_#{c['type']}" : 'container'
                @doc[doc_key] ||= []
                @doc[doc_key] << c['value']
              end
            else
              @doc[k.to_sym] ||= []
              v.each { |vv| @doc[k.to_sym] << vv['value'] }
            end
          end
        end
      end      
    end
  end
  
  
  def copy_facet_fields
    if defined?(@doc)
      facet_fields = ['access_terms']
      facet_fields.each do |ff|
        if @doc[ff.to_sym]
          facet_key = (ff + "_facet").to_sym
          @doc[facet_key] = @doc[ff.to_sym]
        end
      end
    end
  end
  
  
end
