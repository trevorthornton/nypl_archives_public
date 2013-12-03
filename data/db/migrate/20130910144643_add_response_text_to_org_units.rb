class AddResponseTextToOrgUnits < ActiveRecord::Migration
  def change
    add_column :org_units, :email_response_text, :text
  end
end
