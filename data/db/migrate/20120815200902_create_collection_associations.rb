class CreateCollectionAssociations < ActiveRecord::Migration
  
  def change
    create_table :collection_associations do |t|
      t.integer :describable_id
      t.string :describable_type
      t.integer :collection_id
      t.timestamps
    end
    add_index :collection_associations, :describable_id
    add_index :collection_associations, :describable_type
  end
  
end
