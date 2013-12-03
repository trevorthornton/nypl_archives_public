class CatalogImport < ActiveRecord::Base
  
  include CatalogImportUtilityMethods
  
  belongs_to :collection
  
  attr_accessible :collection_id, :bnumber, :catalog_record_updated
  
  attr_accessor :record
  
  def execute
    if !self.collection_id
      puts "Catalog ingest requires a pre-existing collection record :("
      nil
    else
      @collection = Collection.find self.collection_id
      if !self.bnumber
        puts "Can't get data from the catalog with out a b-number :("
        nil
      else
        self.record = NyplCatalogRecord.new(:bnumber => self.bnumber).extract
        updated = self.record[:recordinfo][:lastupdatedate]
        d = updated.split('-').map { |x| x.to_i }
        self.catalog_record_updated = Date.new(d[2],d[0],d[1])
        self.process_description
        self.process_access_terms
        self.save
        # @collection.reload
        # @collection.update_response
      end
    end
  end
  
  
  def valid_bnumber
    NyplCatalogRecord.new(:bnumber => self.bnumber).extract ? true : false
  end
  
  
  def process_description
    self.description_from_marc
    if @collection.description
      @collection.description.attributes = @description
    else
      @collection.description = Description.new(@description)
    end
    @collection.add_object_attributes_from_description
    @collection.save
    @collection.description.save
    @collection.post_ingest_updates(:skip_components => true, :source => 'marc')
  end
  
  
  def process_access_terms
    # Delete existing access_term_associations before creating new ones
    AccessTermAssociation.where(:describable_type => 'Collection',
      :describable_id => @collection.id).each do |a|
        a.destroy
    end
    
    self.access_terms_from_marc.each do |a|
      process_access_term_data(a,'Collection',self.collection.id)
    end
  end
  
  
  def get_element_from_marc(element)
    self.record = NyplCatalogRecord.new(:bnumber => self.bnumber).extract
    @description = { :data => {} }
    case element
    when 'abstract'
      abstract_scope_from_marc(self.record)
    when 'langmaterial'
      ['041','546'].each do |tag|
        if self.record[:fields][tag]
          self.record[:fields][tag].each do |field|
            language_from_marc(tag,field)
          end
        end
      end
    when 'physdesc'
      if self.record[:fields]['300']
        self.record[:fields]['300'].each do |field|
          physdesc_from_marc('300',field)
        end
      end
    end
  
    @description[:data]
  end
  
  
  def description_from_marc   
    @description = { :data => {} }
        
    # unitid from collection identifier
    if @collection
      (@description[:data]['unitid'] ||= []) << {
        'value' => @collection.identifier_value,
        'type' => @collection.identifier_type
      }
    end
    
    self.record[:fields].each do |tag,array|
      array.each do |field|
        case tag
        when '100','110','111'
          origination_from_marc(tag,field)
        when '130','245','260'
          unittitle_unitdate_from_marc(tag,field)
        when '254','255','256'
          materialspec_from_marc(tag,field)
        when '300'
          physdesc_from_marc(tag,field)
        when '041','546'
          language_from_marc(tag,field)
        when '340','500','506','510','524','530','535','536','538','540','544','555','581','770','773','774','787'
          notes_from_marc(tag,field)
        when '351'
          arrangement_from_marc(tag,field)
        when '541'
          acqinfo_from_marc(tag,field)
        end
      end
    end
    # MARC 852 fields need to be processed as a group because they often contain duplicate data
    parse_marc_852(self.record)
    # MARC 520, 545, and 561 fields need to be processed as a group and treated as a single value
    abstract_scope_from_marc(self.record)
    bioghist_from_marc(self.record)
    custodhist_from_marc(self.record)
    compact(@description)
        
    # extended dates
    if @description[:data]['unitdate']
      puts @description[:data]['unitdate'].inspect
      @description[:data]['unitdate'].each do |d|
        date_values = generate_extended_date_values(d)
        date_values.each do |k,v|
          @description[:data][k] ||= v
        end
      end
    end
        
    # turn @description[:data] into JSON before returning
    data_json = JSON.generate(@description[:data])
    @description[:data] = data_json
    @description
  end
  
  
  # Generate access terms from MARC data
  def access_terms_from_marc
    @access_terms = []
    name_subject_fields = ['600','610','611','696','697','698']
    exclude_fields = ('770'..'789').to_a    
    fields = self.record[:fields]
    fields.each do |tag,array|
      # Searches 240, all 6xx and 7xx, excluding 77x and 78x
      if ['100','110','111','240'].include?(tag) || (['6xx','7xx'].include?(tag_range(tag)) && !exclude_fields.include?(tag))
        array.each do |field|
          term_attributes = {}
          term_attributes[:term_type] = access_term_type(tag,field)
          term_attributes[:term_original] = concatenate_subfields(tag,field)
          thesaurus_code = subject_thesaurus_code(tag,field)
          if thesaurus_code
            term_attributes[:term_authorized] = term_attributes[:term_original]
            term_attributes[:authority] = thesaurus_code
            term_attributes[:control_source] = 'marc'
          elsif ('690'..'699').to_a.include?(tag)
            term_attributes[:authority] = 'local'
          end
          term_attributes[:name_subject] = name_subject_fields.include?(tag) ? true : false
          if relator_from_subfields(tag,field)
            term_attributes[:role] = relator_from_subfields(tag,field)[:term]
          end
          if ['100','110','111'].include? tag
            term_attributes[:function] = 'origination'
            term_attributes[:controlaccess] = false
          else
            term_attributes[:controlaccess] = true
          end
          if term_attributes[:term_type] == 'occupation'
            term_attributes[:term_type] = 'topic'
            term_attributes[:function] = 'occupation'
          end
          if !term_attributes[:term_original].blank?
            @access_terms << compact(term_attributes)
          end
        end
      end    
    end
    @access_terms
  end
  
  
  def process_access_term_data(term_data, describable_type, describable_id)
    role = !term_data[:role].nil? ? term_data.delete(:role) : nil
    function = !term_data[:function].nil? ? term_data.delete(:function) : nil
    name_subject = !term_data[:name_subject].nil? ? term_data.delete(:name_subject) : nil
    controlaccess = !term_data[:controlaccess].nil? ? term_data.delete(:controlaccess) : nil
    association_attributes = {
      :describable_type => describable_type,
      :describable_id => describable_id,
      :role => role,
      :name_subject => name_subject,
      :function => function,
      :controlaccess => controlaccess
    }
    compact(association_attributes)
        
    # check for existing
    existing_term = AccessTerm.where(:term_original => term_data[:term_original],
      :term_type => term_data[:term_type]).first
    term = existing_term ? existing_term : AccessTerm.new(term_data)
    existing_term ? term.update_attributes(term_data) : term.save
    
    association_attributes[:access_term_id] = term.id
    
    existing_association = AccessTermAssociation.where(association_attributes).first
    
    begin
      if existing_association
        existing_association.update_attributes(association_attributes)
        puts "Existing access term association updated."
      else
        AccessTermAssociation.create(association_attributes)
        puts "Access term association successfully created."
      end
    rescue Exception => e
      puts "Access term association failed :("
      puts e
    end
  end
  
end
