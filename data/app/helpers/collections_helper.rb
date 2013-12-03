module CollectionsHelper
  
  include ApplicationHelper
  
  def collections_select_options
    options = []
    Collection.find_each do |c|
      data = JSON.parse(c.description.data)
      if !data['origination'].blank?
        origination = data['origination'][0]['value']
        display_value = origination + " - " + c.title
        options << [display_value, c.id]
      end
    end
    options.sort { |a,b| a[0]<=>b[0] }
  end
  
  
  def activation_link(collection)
    path = { :controller => 'collections', :action => 'update', :id => collection.id, :collection => {} }
    if collection.active
      path[:collection][:active] = 0
      link_text = 'deactivate'
    else
      path[:collection][:active] = 1
      link_text = 'activate'
    end
    link_to link_text, path, :method => 'put', :class => 'btn btn-mini'
  end
  
  
  # Fetches collection either by id or identifier value, depending on params present
  def variable_collection_find
    collection = nil
    if params[:find_by_identifier]
      options = { :identifier_value => params[:identifier_value] }
  		collection = Collection.includes(:collection_response, :org_unit).where(options).first
    elsif params[:id]
  		begin
  		  collection = Collection.includes(:collection_response).find params[:id]
		  rescue Exception => e
		    logger.error e
	    end
    end
    collection
  end
  
end
