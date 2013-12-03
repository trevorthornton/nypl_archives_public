class AddBoostQueriesToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :boost_queries, 'longtext'
  end
end
