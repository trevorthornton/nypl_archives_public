class DescriptionsAddDataField < ActiveRecord::Migration
  def change
    add_column :descriptions, :data, 'longtext'
  end
end
