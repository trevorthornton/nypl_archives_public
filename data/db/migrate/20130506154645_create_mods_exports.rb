class CreateModsExports < ActiveRecord::Migration
  def change
    create_table :mods_exports do |t|

      t.timestamps
    end
  end
end
