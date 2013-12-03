class AmatRecord < ActiveRecord::Base
  
  attr_accessible :ead_ingest_error, :verified, :ead_filename, :ead_url, :pdf_filename, :pdf_url, :collection_id, :node_id, :mss_id
  belongs_to :collection
  
end