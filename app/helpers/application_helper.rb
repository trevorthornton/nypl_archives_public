module ApplicationHelper
  
  include BootstrapPaginationHelper
  
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
  
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == ADMIN_USERNAME && password == ADMIN_PASSWORD
    end
  end
  
  def cancel_button
    submit_tag("Cancel", :name => 'cancel')
  end
  
end
