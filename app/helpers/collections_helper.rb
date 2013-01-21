module CollectionsHelper
  
  include ApplicationHelper
  
  def collections_select_options
    options = []
    Collection.find_each do |c|
      context = JSON.parse(c.description.context)
      origination = context['origination'][0]['value']
      display_value = origination + " - " + c.title
      options << [display_value, c.id]
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
  
end
