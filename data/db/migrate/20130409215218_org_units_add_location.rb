class OrgUnitsAddLocation < ActiveRecord::Migration
  def change
    add_column :org_units, :location, :string
  end
end
