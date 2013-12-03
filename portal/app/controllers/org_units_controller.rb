class OrgUnitsController < ApplicationController
  
  include OrgUnitsHelper
  
  def index

    @org_units = OrgUnit.where('collection_count > 0').order('sib_seq asc')
    
  end
  
end
