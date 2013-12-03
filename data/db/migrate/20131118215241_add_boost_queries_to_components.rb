class AddBoostQueriesToComponents < ActiveRecord::Migration
  def change
    add_column :components, :boost_queries, 'longtext'
  end
end
