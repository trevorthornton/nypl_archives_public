class CreateAccessTermAssociations < ActiveRecord::Migration
  def change
    create_table :access_term_associations do |t|
      t.integer :describable_id
      t.string :describable_type
      t.string :role
      t.boolean :controlaccess, :default => true
      t.integer :access_term_id
      t.boolean :name_subject, :default => false
      t.timestamps
    end
    add_index :access_term_associations, :describable_id
    add_index :access_term_associations, :describable_type
  end
end
