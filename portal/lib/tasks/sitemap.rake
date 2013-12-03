namespace :sitemap do

  desc "generate site map"
  task :generate => :environment do
    include ApplicationHelper
    sitemap = File.new("#{Rails.root}/public/sitemap.txt", 'w', :encoding => 'UTF-8')
    Collection.find_each(:conditions => 'active = 1') do |c|
      path = persistent_collection_path(c.attributes.symbolize_keys!)
      url = "http://archives.nypl.org#{path}"
      sitemap.puts url
      puts "Added #{url} to sitemap."
    end
    sitemap.close
  end

end
