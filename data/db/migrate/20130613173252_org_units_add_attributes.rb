class OrgUnitsAddAttributes < ActiveRecord::Migration
  def change
    add_column :org_units, :url, :string
    add_column :org_units, :description, :text
    add_column :org_units, :collection_count, :integer
  end
end