class RemoveDescriptionColumns < ActiveRecord::Migration
  def change
    remove_column :descriptions, :descriptive_identity
    remove_column :descriptions, :content_structure
    remove_column :descriptions, :context
    remove_column :descriptions, :acquisition_processing
    remove_column :descriptions, :related_material
    remove_column :descriptions, :access_use
    remove_column :descriptions, :notes
  end
end
