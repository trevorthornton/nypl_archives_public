class AddRulesToOrgUnit < ActiveRecord::Migration
  def change
    add_column :org_units, :access_rules, :text
  end
end
