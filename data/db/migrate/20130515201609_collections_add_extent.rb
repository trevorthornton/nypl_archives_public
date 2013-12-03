class CollectionsAddExtent < ActiveRecord::Migration
  def change
    add_column :collections, :extent_statement, :string
    add_column :collections, :linear_feet, :float
  end
end
