# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Archives::Application.initialize!

Archives::Application.configure do
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: 'localhost'
  }
  config.action_mailer.raise_delivery_errors = true
end

# Application Constants
SOLR_URL = "***"

ADMIN_USERNAME = "***"
ADMIN_PASSWORD = "***"

ADMIN_EMAIL = "***"