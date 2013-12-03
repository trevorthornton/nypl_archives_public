class AddQuestionableToPlaceAssociations < ActiveRecord::Migration
  def change
    add_column :place_name_associations, :questionable, :boolean, :default => false
  end
end
