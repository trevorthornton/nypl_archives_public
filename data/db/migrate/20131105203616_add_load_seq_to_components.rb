class AddLoadSeqToComponents < ActiveRecord::Migration
  def change
    add_column :components, :load_seq, :integer
    add_index(:components, [:collection_id, :load_seq], :unique => true, :name => 'collection_load_seq')
  end
end
