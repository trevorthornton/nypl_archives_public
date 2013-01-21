module ApiHelper
  include ApplicationHelper
  
  def collection_data(params)
    data = @collection.unit_data
    data[:controlaccess] = @collection.access_term_data
    data[:max_levels] = @collection.max_component_level
    if params[:include_tree].to_i != 0
      data[:tree] = @collection.structure
    end
    if params[:full].to_i != 0
      data[:components] = @collection.all_component_data
    end    
    data.delete_if { |k,v| v.blank? }
    data
  end
  
  
end