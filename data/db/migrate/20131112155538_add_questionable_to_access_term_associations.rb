class AddQuestionableToAccessTermAssociations < ActiveRecord::Migration
  def change
    add_column :access_term_associations, :questionable, :boolean, :default => false
  end
end
