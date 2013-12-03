module ApplicationHelper
    
  DEFAULT_PER_PAGE = 25
  
  
  # NOT SURE THAT THIS SHOULD BE HERE OR SOMEWHERE ELSE
  # Some divisions require the user to choose if they want to request access to materials or just ask a question
  def request_materials_enabled(org_unit_code)
    enabled = ['MSS','BRG','CPS','NYPLA','DAN']
    return enabled.include?(org_unit_code)
  end
  
  
  def page_title
    title = 'archives.nypl.org'
    case params[:controller]
    when 'searches'
      if ['results','collection'].include?(params[:action])
        title += " -- Search results"
      end
    when 'collections'
      if @collection_data
        title += " -- #{@collection_data['title']}"
      end
    when 'org_units'
      title += " -- Repositories"
    end
    title
  end
  
  def pagination_details(params, total)
                
    per_page = params[:per_page].to_i || DEFAULT_PER_PAGE
        
    total_pages = @total_pages ? @total_pages  : (total.to_f / per_page.to_f).ceil
    current_page = params[:page].to_i || 1
    visible_pages = 5
    
    first_visible_page = (current_page / visible_pages) * visible_pages + 1
    last_available_visible = first_visible_page + visible_pages - 1
    last_visible_page = last_available_visible > total_pages ? total_pages : last_available_visible
    if last_visible_page > total_pages
      last_visible_page = total_pages
    end
    
    prev_page = current_page > 1 ? current_page - 1 : nil
    next_page = current_page < total_pages ? current_page + 1 : nil
    
    pagination_options = {
      :visible_pages => visible_pages,
      :total_pages => total_pages,
      :current_page => current_page,
      :first_visible_page => first_visible_page,
      :last_visible_page => last_visible_page,
      :prev_page => prev_page,
      :next_page => next_page
    }
    
  end
  
  # Convert a hash into an array of arrays ([value, key])
  #  passed to options_for_select to generate options for select fields
  def hash_to_select_options(hash)
    options = []
    hash.each { |k,v| options << [v,k] }
    options
  end

  def is_active?(controller_name, page_name)
    "active" if (params[:controller] == controller_name && params[:action] == page_name)
  end
  
  # Generates persistent public URL for collections
  def persistent_collection_path(args={})
    if args[:identifier_value]
      if args[:org_unit_code]
        "/#{args[:org_unit_code].downcase}/#{args[:identifier_value]}"
      else
        result = OrgUnit.find_by_sql ["select o.code from org_units o join collections c on c.org_unit_id = o.id where c.identifier_value = ?", args[:identifier_value]]
        "/#{result.first.code.downcase}/#{args[:identifier_value]}"
      end
    elsif args[:id] && (args[:id].kind_of? Numeric)
      result = ActiveRecord::Base.connection.select_all( "SELECT c.identifier_value as identifier_value, o.code as code FROM collections c JOIN org_units o ON o.id = c.org_unit_id WHERE c.id = #{args[:id]}" )
      if result.first['code'] && result.first['identifier_value']
        "/#{result.first['code'].downcase}/#{result.first['identifier_value'].downcase}"
      else
        "/collection/#{args[:id]}"
      end
    else
      raise ArgumentError, 'parameters insufficient to generate link'
    end
  end
  
  # keys in args are strings, as they are in a Solr doc
  def persistent_component_path(args={})
    if !args['id']
      raise ArgumentError, 'parameters insufficient to generate link'
    else
      if args['collection_identifier_value'] && args['collection_org_unit']
        persistent_path_params = { :identifier_value => args['collection_identifier_value'], :org_unit => args['collection_org_unit'] }
      elsif args['collection_id']
        persistent_path_params = { :id => args['collection_id'] }
      else
        raise ArgumentError, 'parameters insufficient to generate link'
      end
      component_link = persistent_collection_path(persistent_path_params)
      component_link += "#c#{args['id']}"
    end
  end
  
  
  def valid_org_unit_code?(code)
    OrgUnit.where(:code => code.upcase).first ? true : false
  end
  
  def org_unit_name(org_unit_id, type = 'default')
    org_unit = OrgUnit.find org_unit_id
    return type == 'short' ? org_unit.name_short : org_unit.name
  end
  
  def messages
    { :not_found => "You tried to access a page that does not exist." }
  end
  
  def file_type_labels
    {
      'pdf' => 'PDF',
      'doc' => 'MS Word',
      'xls' => 'MS Excel',
      'txt' => 'Text',
      'jpg' => 'JPEG image' 
    }
  end
  
  
  
  
  
  
  
end
