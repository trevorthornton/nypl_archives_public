class DigtialObjectUpdates < ActiveRecord::Migration
  def change
    add_column :component_responses, :digital_objects, 'longtext'
    add_column :collection_responses, :digital_objects, 'longtext'
    add_column :nypl_repo_objects, :resource_type, :string
  end
end