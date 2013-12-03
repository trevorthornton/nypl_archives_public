class AlterComponentLoadSeqIndex < ActiveRecord::Migration
  def change
    remove_index :components, :name => 'collection_load_seq'
    add_index(:components, [:collection_id, :load_seq], :name => 'collection_load_seq')
  end
end
