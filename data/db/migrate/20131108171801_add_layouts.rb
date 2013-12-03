class AddLayouts < ActiveRecord::Migration
  def change
    
    create_table :component_layouts do |t|
      t.string :name
      t.text :description
      t.timestamps
    end
    
    add_column :collections, :component_layout_id, :integer
    
  end
end
