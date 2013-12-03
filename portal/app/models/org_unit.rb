class OrgUnit < ActiveRecord::Base
  
  include ReadOnlyModels
  
  has_many :collections
  
  def find_by_code(code)
    OrgUnit.where(:code => code).first
  end
  
end