class CreateGuideGuideAssociations < ActiveRecord::Migration
  def change
    create_table :guide_guide_associations do |t|
      t.integer :parent_guide_id
      t.integer :child_guide_id
      t.timestamps
    end
  end
end
