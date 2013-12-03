class CreateExternalResource < ActiveRecord::Migration
  def change
    create_table :external_resources do |t|
      t.string :describable_type
      t.integer :describable_id
      t.string :title
      t.string :description
      t.string :resource_type
      t.string :url
      t.timestamps
    end
    remove_column :documents, :url
    remove_column :documents, :filename
  end
end
