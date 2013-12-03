class ComponentsAddOrigination < ActiveRecord::Migration
  def change
    add_column :components, :origination, :string
  end
end
