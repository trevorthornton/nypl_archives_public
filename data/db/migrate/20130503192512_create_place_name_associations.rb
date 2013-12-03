class CreatePlaceNameAssociations < ActiveRecord::Migration
  def change
    create_table :place_name_associations do |t|
      t.integer :place_id
      t.integer :name_association_id
      t.timestamps
    end
  end
end