class RSolr::Connection
  alias :old_setup_raw_request :setup_raw_request

  def setup_raw_request request_context
    raw_request = old_setup_raw_request request_context
    raw_request.basic_auth(SOLR_USERNAME, SOLR_PASSWORD);
    raw_request
  end
 
end