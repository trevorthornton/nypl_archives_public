class CreateDescriptions < ActiveRecord::Migration
  def change
    create_table :descriptions do |t|
      t.integer :describable_id
      t.string :describable_type
      # Note: using MySQL-specific LONGTEXT datatype for fields that will store JSON objects
      t.column(:descriptive_identity, 'longtext')
      t.column(:content_structure, 'longtext')
      t.column(:context, 'longtext')
      t.column(:acquisition_processing, 'longtext')
      t.column(:related_material, 'longtext')
      t.column(:access_use, 'longtext')
      t.column(:notes, 'longtext')
      t.timestamps
    end
    add_index :descriptions, :describable_id
    add_index :descriptions, :describable_type
  end
end
