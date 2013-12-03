class AddAttributesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :username, :string
    add_column :users, :role, :string, :default => 'viewer'
    add_column :users, :name_first, :string
    add_column :users, :name_last, :string
    create_table(:user_org_unit_associations) do |t|
      t.integer :user_id
      t.integer :org_unit_id
      t.timestamps
    end
  end
end
