class CreateComponents < ActiveRecord::Migration
  def change
    create_table :components do |t|
      t.string :title
      t.string :identifier_value
      t.string :identifier_type
      t.integer :collection_id
      t.integer :parent_id
      t.integer :sib_seq
      t.boolean :has_children, :default => false
      t.integer :level_num
      t.string :level_text
      t.integer :top_component_id
      t.integer :max_depth
      t.integer :org_unit_id
      t.timestamps
    end
    add_index :components, :title
    add_index :components, :identifier_value
    add_index :components, :identifier_type
    add_index :components, :org_unit_id
    add_index :components, :collection_id
    add_index :components, :parent_id
    add_index :components, :top_component_id
  end
end
