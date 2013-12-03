class CreateCatalogImports < ActiveRecord::Migration
  def change
    create_table :catalog_imports do |t|
      t.string :bnumber
      t.integer :collection_id
      t.date :catalog_record_updated
      t.timestamps
    end
  end
end
