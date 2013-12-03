class Document < ActiveRecord::Base
  
  attr_accessible :document_type, :description, :title, :describable_type, :describable_id, :file, :index_only
  
  belongs_to :describable, :polymorphic => true
  mount_uploader :file, FileUploader
  
  validates :title, presence: true
  
  after_save :update_describable_response

  
  private
  
  def update_describable_response
    self.describable.update_response(:limit => 'desc_data', :skip_components => true)
  end
  
end
