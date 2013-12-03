class UsersController < ApplicationController
  
  def index
    begin
      @page = params[:page] || 1
      @per_page = params[:per_page] || 30
      @users = User.paginate(:page => @page, :per_page => @per_page) || []
    rescue Exception => e
      flash[:error] = e
      redirect_to '/'
    end
  end
  
  def new
    if !current_user
      redirect_to 'users/sign_up'
    elsif !current_user.can_create?(User)
      flash[:warning] = "You do not have sufficient permissions to create a new user."
      redirect_to request.referer
    else
      @user = User.new
      @org_unit_options = []
      current_user.accessible_org_units.each { |o| @org_unit_options << [o.name, o.id] }
      @role_options = current_user.assignable_roles
    end
    
  end
  
  
  def create
    org_units = params[:user][:org_units] ? params[:user].delete(:org_units) : []
    @user = User.new(params[:user])
    begin
      @user.save!
      puts @user.inspect
      org_units.each do |o|
        UserOrgUnitAssociation.create(:user_id => @user.id, :org_unit_id => o.to_i)
      end
      flash[:message] = "New user created: #{@user.email}."
      redirect_to :action => 'index'
      return
    rescue Exception => e
      puts e
      flash[:error] = e
      redirect_to '/'
      return
    end
  end
  
  
  def show
    begin
      @user = User.find params[:id]
    rescue Exception => e
      flash[:error] = e
      redirect_to 'users/index'
    end
  end

  def edit
    begin
      @user = User.find params[:id]
      @org_unit_options = []
      OrgUnit.all(:order => ['center','name']).each do |o|
        option = [o.name,o.id]
        if !current_user.accessible_org_unit_ids.include?(o.id)
          option << 'disabled'
        end
        @org_unit_options << option
      end
      @role_options = current_user.assignable_roles
    rescue Exception => e
      flash[:error] = e
      redirect_to :action => 'index'
    end
  end
  
  def update
    if (params[:commit] != 'Cancel') && params[:user]
      begin
        @user = User.find params[:id]
        
        puts @user.inspect
        
        org_units = params[:user][:org_units] ? params[:user].delete(:org_units) : []
        
        if params[:user][:password].blank?
          params[:user].delete(:password)
        end
        
        @user.update_attributes(params[:user])
        @user.reload
        
        puts @user.inspect
        
        # Modify user_org_unit_associations
        existing_org_unit_ids = @user.org_units.map { |o| o.id.to_s }
        org_units.each do |o|
          if existing_org_unit_ids.include? o
            existing_org_unit_ids.delete(o)
          else
            UserOrgUnitAssociation.create(:user_id => @user.id, :org_unit_id => o)
          end
        end
        
        
        UserOrgUnitAssociation.where(:org_unit_id => existing_org_unit_ids, :user_id => @user.id).each { |o| o.destroy }
        flash[:message] = "User #{@user.email} updated."
        redirect_to :action => 'index'
        return
      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
        flash[:error] = e
        redirect_to :action => 'index'
        return
      end
    else
      redirect_to :action => 'index'
    end
  end
  
  def delete
  end

  def destroy
  end
end
