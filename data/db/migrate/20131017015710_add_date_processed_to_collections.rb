class AddDateProcessedToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :date_processed, :integer
  end
end
