class ComponentsController < ApplicationController
  
  include ComponentsHelper
  
  # before_filter :authenticate
  
  rescue_from 'ActiveRecord::RecordNotFound' do |exception|
    flash[:error] = params[:id].nil? ? "Cannot find component without ID" : "Component does not exist with ID '#{params[:id]}'"
    puts exception
    redirect_to request.referer.nil? ? '/' : request.referer
  end
  
  def index
  end  
  
  def new
  end
  
  def create
  end
  
  def show
    session[:return_to] = request.fullpath
    @component = Component.find params[:id]
    @collection = @component.collection
    @description = JSON.parse(@component.description.data)
    @children = @component.children
    @component_ancestors = @component.component_ancestors
    @documents = @component.documents
    @external_resources = @component.external_resources
    @repo_objects = NyplRepoObject.where(:describable_type => "Component", :describable_id => params[:id])
    @boost_queries = @component.boost_queries ? JSON.parse(@component.boost_queries) : []
    case params[:format]
    when 'mods'
      render :xml => @component.mods
    else
      render
    end
  end
  
  def add_uuid

    if !params[:uuid].blank?

      if params[:uuid].to_s == '-1'

          repo_objects = NyplRepoObject.where(:describable_type => "Component", :describable_id => params[:id])
          repo_objects.each do |r|

            x = NyplRepoObject.find(r.id)
            x.destroy

          end

        x = Component.find(params[:id])
        x.update_nypl_repo_captures
        x.update_response

      elsif params[:uuid].to_s == '0'

        x = Component.find(params[:id])
        x.update_nypl_repo_captures
        x.update_response

      else


        x = NyplRepoObject.new(describable_type: 'Component', describable_id: params[:id], uuid: params[:uuid])
        x['resource_type'] = "image"
        x.save

        x = Component.find(params[:id])
        x.update_nypl_repo_captures
        x.update_response


      end

    end


    redirect_to "/components/" + params[:id].to_s + "#respository"

  end
  
  def edit
    @component = Component.find params[:id]
    @record = @component
    @collection = @component.collection
    @description = @component.description
    @update_type = params[:update_type]
    @boost_queries = @component.boost_queries ? JSON.parse(@component.boost_queries) : []
  end
  
  
  def update
    
    if params[:commit] != 'Cancel'
      
      @component = Component.find params[:id]
      
      if params[:component][:boost_queries]
        queries_array = params[:component][:boost_queries].split(',')
        queries_array.each { |q| q.strip! }
        params[:component][:boost_queries] = JSON.generate(queries_array)
      end
      
      if !params[:component].blank?
        @component.update_attributes(params[:component])
      end
      
    end

    redirect_to session[:return_to]
    
  end
  
  def destroy
  end
  
  def export
    @component = Component.find params[:id]
    @collection = @component.collection
  end
  
end
