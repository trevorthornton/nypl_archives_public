class AccessTermAssociationFunction < ActiveRecord::Migration
  def change
    add_column :access_term_associations, :function, :string
  end
end
