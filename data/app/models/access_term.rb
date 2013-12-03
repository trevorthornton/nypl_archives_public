class AccessTerm < ActiveRecord::Base
  attr_accessible :term_original, :term_authorized, :term_type, :authority, :authority_record_id, :value_uri, :control_source
  
  attr_accessor :name_subject, :function
  
  has_many :collections, :through => :access_term_associations, :conditions => "describable_type = 'Collection'"
  has_many :components, :through => :access_term_associations, :conditions => "describable_type = 'Component'"
  
  has_many :access_term_associations, :dependent => :destroy
  has_many :place_name_associations, :conditions => "term_type = 'geogname'", :foreign_key => "place_id", :dependent => :destroy
  
  after_save do
    # self.access_term_associations.each { |a| a.touch }
  end
  
  def strip_punctuation
    clean_term = self.term_original.clone
    
    clean_term.strip!
    
    if clean_term.match(/^\".*\"$/)
      clean_term.gsub!(/^\"/,'')
      clean_term.gsub!(/\"$/,'')
    end
    
    if clean_term.match(/\,$/)
      clean_term.gsub!(/\,$/,'')
    end 
    
    if clean_term.match(/^[\,\-]*/)
      clean_term.gsub!(/^[\,\-]*/,'')
    end
    
    clean_term.strip!
    
    if clean_term != self.term_original
      self.update_attribute(:term_original, clean_term)
    end
  end
  
  def self.strip_punctuation
    find_each { |t| t.strip_punctuation }
  end
  
  
  
  def self.remove_duplicates
    # :batch_size => 1 forces records to be loaded one at a time, rather than in proper batches,
    # because the other way results in processing records that were destroyed in previous iterations
    # resulting in destruction of the orginal (non-duplicate) term
    find_each(:batch_size => 1) do |t|
      if t
        t.remove_duplicates
      end
    end
  end
  
  
  #############################################################
  # Instance methods
  #############################################################


  #############################################################
  # Retrieval & calculation methods
  #############################################################
  
  def term_hash
    term_text = self.term_authorized ? self.term_authorized : self.term_original
    term_hash = { :id => self.id, :term => term_text, :type => self.term_type, :source => self.authority }
    term_hash
  end
  
  
  #############################################################
  # Update methods
  #############################################################
  
  def remove_duplicates
    duplicates = AccessTerm.where("term_original = ? and id != ? and term_type = ?", self.term_original, self.id, self.term_type)
    if !duplicates.empty?
      duplicates.each do |d|
        # update nil attributes in t with d attributes where present
        term_attributes = [:term_authorized,:authority,:authority_record_id,:value_uri,:control_source]
        term_attributes.each do |ta|
          if d[ta] && !self[ta]
            self[ta] = d[ta]
          end
        end
        associations = AccessTermAssociation.where(:access_term_id =>d.id)
        associations.each do |a|
          a.update_attribute(:access_term_id, self.id)
        end
        d.destroy
      end
      self.save
    end
  end
  
end
