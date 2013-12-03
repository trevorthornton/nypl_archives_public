class OrgUnit < ActiveRecord::Base
  attr_accessible :name, :name_short, :code, :center, :location, :marc_org_code,
  :standard_access_note, :url, :description, :collection_count, :email, :access_rules, :email_response_text
  
  has_many :user_org_unit_associations
  has_many :users, :through => :user_org_unit_association
  has_many :collections
  
  def update_collection_count
    count = Collection.where(:org_unit_id => self.id).count
    self.update_attribute(:collection_count, count)
  end
  
  def self.update_collection_count
    find_each { |o| o.update_collection_count }
  end
  
end
