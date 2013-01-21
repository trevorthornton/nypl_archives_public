class OrgUnit < ActiveRecord::Base
  attr_accessible :name, :name_short, :code, :center, :marc_org_code
end
