class Document < ActiveRecord::Base
  
  include ReadOnlyModels
  
  belongs_to :describable, :polymorphic => true
  mount_uploader :file, FileUploader

end
