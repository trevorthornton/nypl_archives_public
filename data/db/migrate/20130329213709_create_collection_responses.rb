class CreateCollectionResponses < ActiveRecord::Migration
  def change
    create_table :collection_responses do |t|
      t.integer :collection_id
      t.column(:desc_data, 'longtext')
      t.column(:structure, 'longtext')
      t.timestamps
    end
    add_index :collection_responses, :collection_id
  end
end
