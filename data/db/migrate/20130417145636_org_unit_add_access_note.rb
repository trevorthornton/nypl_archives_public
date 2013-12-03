class OrgUnitAddAccessNote < ActiveRecord::Migration
  def change
    add_column :org_units, :standard_access_note, :text
  end
end
