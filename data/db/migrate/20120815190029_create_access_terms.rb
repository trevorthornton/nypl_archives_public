class CreateAccessTerms < ActiveRecord::Migration
  
  def change
    create_table :access_terms do |t|
      t.string :term_original
      t.string :term_authorized
      t.string :term_type
      t.string :authority
      t.string :authority_record_id
      t.string :value_uri
      t.integer :control_source
      t.timestamps
    end
    add_index :access_terms, :term_original
    add_index :access_terms, :term_authorized
    add_index :access_terms, :value_uri
  end
  
end
