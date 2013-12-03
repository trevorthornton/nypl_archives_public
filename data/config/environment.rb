# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Archives::Application.initialize!

AUTHORITY_QUERY_URL = "***"

SOLR_URL = "***"
SOLR_WRITE_URL = "***"

NYPL_REPO_API_URL = "***"
NYPL_REPO_API_USERNAME = "***"
NYPL_REPO_API_PASSWORD = "***"
NYPL_REPO_API_KEY = "***"
NYPL_REPO_API_AUTH_HEADER = 'Token token="' + NYPL_REPO_API_KEY + '"'

ADMIN_USERNAME = '***'
ADMIN_PASSWORD = '***'