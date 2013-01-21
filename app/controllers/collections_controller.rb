class CollectionsController < ApplicationController
  
  include CollectionsHelper
  
  before_filter :authenticate
  
  def index
    @page = params[:page] || 1
    @per_page = params[:per_page] || 10
    @collections = Collection.includes(:org_unit).paginate(:page => @page, :per_page => @per_page).order(:title)
  end
  
  
  def show
    @collection = Collection.find params[:id]
  end

  
  def new
    
  end
  
  
  def create
    
  end
  
  
  def edit
    
  end
  
  
  def update
    session[:return_to] = request.referer
    if params[:collection]
      @collection = Collection.find params[:id]
      @collection.update_attributes params[:collection]
    end
    redirect_to session[:return_to]
  end
  
  
  def destroy
    
  end
  
  
end