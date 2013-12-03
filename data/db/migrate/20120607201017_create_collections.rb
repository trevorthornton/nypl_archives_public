class CreateCollections < ActiveRecord::Migration
  def change
    create_table :collections do |t|
      t.string :title
      t.string :origination
      t.string :date_statement
      t.integer :keydate
      t.string :identifier_value
      t.string :identifier_type
      t.string :bnumber
      t.integer :org_unit_id
      t.boolean :active, :default => true
      t.timestamps
    end
    add_index :collections, :title
    add_index :collections, :identifier_value
    add_index :collections, :identifier_type
    add_index :collections, :org_unit_id
    add_index :collections, :bnumber
    add_index :collections, :keydate
  end
end
