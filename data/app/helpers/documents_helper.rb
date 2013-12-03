module DocumentsHelper
  
  include ApplicationHelper
  
  def document_types
    [ 'other finding aid', 'inventory', 'index', 'names list',
      'transcript', 'documentation', 'other' ]
  end
  
  def document_type_select_options
    options = []
    document_types.each do |d|
      options << [d,d]
    end
    options
  end
  
end