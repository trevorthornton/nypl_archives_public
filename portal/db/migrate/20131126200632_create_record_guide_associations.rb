class CreateRecordGuideAssociations < ActiveRecord::Migration
  def change
    create_table :record_guide_associations do |t|
      t.text :description
      t.string :describable_type
      t.integer :describable_id
      t.integer :guide_id
      t.timestamps
    end
  end
end
