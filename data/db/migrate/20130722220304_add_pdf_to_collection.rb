class AddPdfToCollection < ActiveRecord::Migration
  def change
    add_column :collections, :pdf_finding_aid, :string
  end
end
