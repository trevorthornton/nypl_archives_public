class OrgUnitsController < ApplicationController
  
  include OrgUnitsHelper
  
  before_filter :authenticate
  
  def new
    session[:return_to] = request.referer
    @org_unit = OrgUnit.new
  end

  def index
    @org_units = OrgUnit.order(:name).all
  end

  def create
    if params[:cancel]
      redirect_to session[:return_to]
    else
      # new object with form params
      @org_unit = OrgUnit.new(params[:org_unit])
      if @org_unit.name_short.nil?
        @org_unit.name_short = @org_unit.name
      end
      # Save
      if @org_unit.save
        # On success, show record details?
        redirect_to(:action => 'index')
      else
        # On fail, go back to form
        render('new')
      end
    end
  end

  def show
    @org_unit = OrgUnit.find(params[:id])
  end

  def edit
    @org_unit = OrgUnit.find(params[:id])
  end

  def update
    @org_unit = OrgUnit.find(params[:id])
    if params[:org_unit][:name_short].blank?
      params[:org_unit][:name_short] = params[:org_unit][:name]
    end
    # Update
    if @org_unit.update_attributes(params[:org_unit])
      # On success, show record details?
      redirect_to(:action => 'index')
    else
      # On fail, go back to form
      render('edit')
    end
  end

  def delete
    @org_unit = OrgUnit.find(params[:id])
  end

  def destroy
    @org_unit = OrgUnit.find(params[:id])
    @org_unit.destroy
  end

end