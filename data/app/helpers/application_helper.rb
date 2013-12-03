module ApplicationHelper
  
  include BootstrapPaginationHelper
  
  
  DEFAULT_PER_PAGE = 25
  
  def pagination_details(params, total)
                
    per_page = params[:per_page].to_i || DEFAULT_PER_PAGE
        
    total_pages = (total.to_f / per_page.to_f).ceil
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
  
  
  def library_centers
    centers = {
      'SASB' => {
        :name => 'Stephen A. Schwarzman Building',
        :name_short => 'Schwarzman',
        :marc_org_code => ''},
      'SC' => {
        :name => 'Schomburg Center for Research in Black Culture',
        :name_short => 'Schomburg',
        :marc_org_code => ''},
      'LPA' => {
        :name => 'New York Public Library for the Performing Arts, Dorothy and Lewis B. Cullman Center',
        :name_short => 'LPA',
        :marc_org_code => ''},
      'SIBL' => {
        :name => 'Science, Industry and Business Library',
        :name_short => 'SIBL',
        :marc_org_code => ''},
      'MML' => {
        :name => 'Mid-Manhattan Library',
        :name_short => 'Mid-Manhattan',
        :marc_org_code => ''}
    }
  end
  
  def library_center_select_options
    options = []
    library_centers.each do |code,hash|
      option = [hash[:name], code]
      options << option
    end
    return options
  end

  def solr_running
    !Delayed::Job.where('handler like "%!ruby/struct:DelayedSolrIndex%"').blank?
  end

  def solr_last_update
    SearchIndex.last()[:created_at].to_formatted_s(:short)
  end

  
  def authenticate
    if (['new','edit'].include? params[:action]) || ((params[:controller] == 'search_indices') && params[:action] == 'update')
      authenticate_or_request_with_http_basic do |username, password|
        username == ADMIN_USERNAME && password == ADMIN_PASSWORD
      end
    end
  end
  
  
  def cancel_button
    submit_tag("Cancel", :name => 'cancel')
  end
  
  def description_areas
    {
      :descriptive_identity => "Descriptive identity",
      :content_structure => "Content/structure",
      :context => "Context",
      :acquisition_processing => "Acquisition/processing",
      :access_use => "Access/use",
      :related_material => "Related material",
      :notes => "Notes"
    }
  end
  
end
