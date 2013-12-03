class UserOrgUnitAssociation < ActiveRecord::Base
  
  # Setup accessible (or protected) attributes for your model
  attr_accessible :user_id, :org_unit_id
  
  belongs_to :user
  belongs_to :org_unit
end
