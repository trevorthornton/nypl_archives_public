class CreateNyplRepoObjects < ActiveRecord::Migration
  def change
    create_table :nypl_repo_objects do |t|
      t.integer :describable_id
      t.string :describable_type
      t.string :uuid
      t.integer :total_captures
      t.column(:capture_ids, 'longtext')
      t.integer :sib_seq
      t.timestamps
    end
    add_index :nypl_repo_objects, :describable_id
    add_index :nypl_repo_objects, :describable_type
  end
end
