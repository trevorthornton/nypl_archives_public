class CollectionAddCallNumber < ActiveRecord::Migration
  def change
    add_column :collections, :call_number, :string
  end
end
