class CollectionHierarchyAttributes < ActiveRecord::Migration
  def change
    add_column :collections, :max_depth, :integer
    add_column :collections, :series_count, :integer
  end
end
