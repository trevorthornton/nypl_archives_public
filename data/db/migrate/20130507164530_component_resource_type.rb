class ComponentResourceType < ActiveRecord::Migration
  def change
    add_column :components, :resource_type, :string
  end
end
