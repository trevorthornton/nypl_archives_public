class RecordGuideAssociation < ActiveRecord::Base
  attr_accessible :describable_type, :describable_id, :guide_id
  belongs_to :describable, :polymorphic => true
  belongs_to :guide
end
