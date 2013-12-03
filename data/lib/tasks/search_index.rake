namespace :search_index do

  desc "delta update"
  task :update, [:update_type] => :environment do |t, args|
    update_type = args[:update_type] || 'delta'
    puts "Performing #{update_type} index..."
    i = SearchIndex.new(:index_type => update_type)
    i.execute
  end

end
