class CollectionAssociationsController < ApplicationController
  
  include CollectionAssociationsHelper
  
  before_filter :authenticate
  
  # OK, listen:
  # collection_associations are actually going to be bulk added/edited,
  # so these actions won't receive an id for the collection_association model,
  # they receive describable_id/describable_type for the 'subject' collection
  # (where the related collection is the object, know what I mean?)
  # and an array of related collection ids.
  # Got it?
  
  def edit
    @describable_type = params[:describable_type] || 'Collection'
    @describable_id = params[:describable_id]
    
    case @describable_type
    when 'Collection'
      @collection = Collection.find params[:describable_id]
      @collection_options = Collection.where("id != #{@collection.id}").order(:origination)
      @object = @collection
    when 'Component'
      @component = Component.find params[:describable_id]
      @collection_options = Collection.where("id != #{@component.collection_id}").order(:origination)
      @object = @component
    end
    
  end
  
  
  def update
=begin
# in progress    
    case @describable_type
    when 'Collection'
      @collection = Collection.find params[:describable_id]
      @object = @collection
    when 'Component'
      @component = Component.find params[:describable_id]
      @object = @component
    end
    params[:related_collections].each do |rc|
      @object.related_collection.build(:collection_id => rc.to_i)
      @object.related_collection.save
    end
=end    
    redirect_to request.referer
  end


  def destroy
    
  end
  
end
