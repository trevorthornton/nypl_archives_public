# lib/modules/delayed_solr_index.rb

class DelayedSolrIndex < Struct.new(:type)
  def perform
      system("cd #{Rails.root} && RAILS_ENV=#{Rails.env} bundle exec rake search_index:update['#{:type} '] >> log/delayed_solr_index.log")
  end
end
