class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.string :describable_type
      t.integer :describable_id
      t.string :document_type
      t.string :filename
      t.string :url
      t.string :description
      t.string :title
      t.timestamps
    end
  end
end
