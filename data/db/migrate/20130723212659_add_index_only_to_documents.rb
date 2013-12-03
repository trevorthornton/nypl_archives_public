class AddIndexOnlyToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :index_only, :boolean, default: 0
  end
end
