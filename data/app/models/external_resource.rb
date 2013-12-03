class ExternalResource < ActiveRecord::Base
  
  attr_accessible :resource_type, :filename, :url, :description, :title, :describable_type, :describable_id
  
  belongs_to :describable, :polymorphic => true
  
  after_save :update_describable_response
  
  
  private
  
  def update_describable_response
    self.describable.update_response(:limit => 'desc_data')
  end
  
end
