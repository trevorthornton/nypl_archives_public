class CreateEadIngests < ActiveRecord::Migration
  def change
    create_table :ead_ingests do |t|
      t.integer :collection_id
      t.string :filename
      t.string :update_type
      t.timestamps
    end
  end
end
