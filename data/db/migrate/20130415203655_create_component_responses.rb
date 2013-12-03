class CreateComponentResponses < ActiveRecord::Migration
  def change
    create_table :component_responses do |t|
      t.integer :component_id
      t.column(:desc_data, 'longtext')
      t.column(:structure, 'longtext')
      t.timestamps
    end
    add_index :component_responses, :component_id
  end
end