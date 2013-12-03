class DocumentsController < ApplicationController
  
  include DocumentsHelper
  
  before_filter :authenticate
  
  def new 
    @document = Document.new(:describable_type => params[:describable_type], :describable_id => params[:describable_id])
    @record = ActiveRecord.const_get(params[:describable_type]).find(params[:describable_id])
    render :layout => params[:layout] == 'false' ? false : true
  end
  
  
  def create
    if params[:commit] == 'Cancel'
      redirect_to session[:return_to]
    else
      @document = Document.new(params[:document])

      @document.save!

      if params[:document]['describable_type'] == 'Component'
        c = Component.find(params[:document]['describable_id'])
      else
        c = Collection.find(params[:document]['describable_id'])        
      end
      c.update_response


      redirect_to session[:return_to]
    end
  end

  def destroy

    document = Document.find params[:id]  
    if document['describable_type'] == 'Component'
      c = Component.find(document['describable_id'])
    else
      c = Collection.find(document['describable_id'])        
    end
    

    document.destroy

    c.update_response


    redirect_to session[:return_to]

  end


  def edit
    @document = Document.find params[:id]
  end


  def update
    @document = Document.find params[:id]
    @document.update_attributes(params[:document])
    redirect_to session[:return_to]
  end
  
end
