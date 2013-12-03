class CreateSearchIndices < ActiveRecord::Migration
  def change
    create_table :search_indices do |t|
      t.string :index_type
      t.integer :adds
      t.integer :updates
      t.integer :deletes
      t.integer :processing_errors
      t.timestamps
    end
  end
end