module ExternalResourcesHelper
  
  include ApplicationHelper
  
  def resource_types
    [ 'index', 'reference source', 'other' ]
  end
  
  def resource_type_select_options
    options = []
    resource_types.each do |d|
      options << [d,d]
    end
    options
  end

end
