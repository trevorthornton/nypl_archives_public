class CreateGuides < ActiveRecord::Migration
  def change
    create_table :guides do |t|
      t.string :title
      t.text :description
      t.string :url_token
      t.integer :user_id
      t.timestamps
    end
  end
end
