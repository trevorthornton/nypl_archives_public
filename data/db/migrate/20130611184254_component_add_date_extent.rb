class ComponentAddDateExtent < ActiveRecord::Migration
  def change
    add_column :components, :date_statement, :string
    add_column :components, :extent_statement, :string
    add_column :components, :linear_feet, :float
  end
end
