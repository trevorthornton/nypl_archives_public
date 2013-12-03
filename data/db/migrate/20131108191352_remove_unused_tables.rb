class RemoveUnusedTables < ActiveRecord::Migration
  
  def change
    drop_table :catalog_ingests
    drop_table :amat_temp
  end
end
