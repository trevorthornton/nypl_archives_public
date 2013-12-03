class AccessTermAssociation < ActiveRecord::Base
  
  attr_accessible :describable_id, :describable_type, :access_term_id, :controlaccess, :role, :name_subject, :function, :questionable
  
  belongs_to :describable, :polymorphic => true
  belongs_to :access_term
  has_many :place_name_associations, :foreign_key => "name_association_id", :dependent => :destroy
  
  after_save do
    self.describable.touch
  end
  
  before_destroy do
    if self.describable
      self.describable.touch
    end
  end
  
  def remove_duplicates
    duplicates = AccessTermAssociation.where(:describable_type => self.describable_type,
      :describable_id => self.describable_id, :access_term_id => self.access_term_id).
      where("id != ?", self.id)
    if self.role
      duplicates.where("role = ? or role is null", self.role)
    end
    
    if !duplicates.empty?
      duplicates.each do |d|
        attributes = [:role, :controlaccess, :name_subject, :function]
        attributes.each do |a|
          if d[a] && !self[a]
            self[a] = d[a]
          end
        end
        d.destroy
      end
      self.save
    end
  end
  
  
  def term_hash
    if self.access_term
      term_hash = self.access_term.term_hash
      term_hash.merge!({ :function => self.function, :role => self.role,
        :controlaccess => self.controlaccess, :questionable => self.questionable })
      term_hash
    end
  end
  
  
  def self.remove_duplicates
    find_each do |a|
      if a
        a.remove_duplicates
      end
    end
  end
  
end