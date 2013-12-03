class ExternalResourcesController < ApplicationController
  
  include ExternalResourcesHelper
  
  before_filter :authenticate
  
  def new 
    @external_resource = ExternalResource.new(:describable_type => params[:describable_type], :describable_id => params[:describable_id])
    @record = ActiveRecord.const_get(params[:describable_type]).find(params[:describable_id])
    render :layout => params[:layout] == 'false' ? false : true
  end
  
  def create
    if params[:commit] == 'Cancel'
      redirect_to session[:return_to]
    else
      @external_resource = ExternalResource.new(params[:external_resource])
      @external_resource.save!

      if params[:external_resource]['describable_type'] == 'Component'
        c = Component.find(params[:external_resource]['describable_id'])
      else
        c = Collection.find(params[:external_resource]['describable_id'])        
      end

      c.update_response

      redirect_to session[:return_to]
    end
  end

  def destroy

    external_resource = ExternalResource.find params[:id]    

    if external_resource['describable_type'] == 'Component'
      c = Component.find(external_resource['describable_id'])
    else
      c = Collection.find(external_resource['describable_id'])      
    end

    external_resource.destroy
  
    c.update_response

    redirect_to session[:return_to]

  end

  def edit
    @external_resource = ExternalResource.find params[:id]
  end

  def update
    @external_resource = ExternalResource.find params[:id]
    @external_resource.update_attributes(params[:external_resource])
    redirect_to session[:return_to]
  end
end
