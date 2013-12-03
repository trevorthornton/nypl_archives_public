class SearchIndexLimit < ActiveRecord::Migration
  def change
    add_column :search_indices, :index_scope, :string
  end
end
