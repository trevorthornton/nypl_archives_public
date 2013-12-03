class AddSibSeqToOrgUnits < ActiveRecord::Migration
  def change
    add_column :org_units, :sib_seq, :integer
  end
end
