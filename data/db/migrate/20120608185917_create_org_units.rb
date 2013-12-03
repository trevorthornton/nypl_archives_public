class CreateOrgUnits < ActiveRecord::Migration
  def change
    create_table :org_units do |t|
      t.string :name
      t.string :name_short
      t.string :code
      t.string :center
      t.string :marc_org_code
      t.timestamps
    end
  end
end
