class OrgUnitsEmail < ActiveRecord::Migration
  def change
    add_column :org_units, :email, :string
  end
end
