class ApiController < ApplicationController
  
  include ApiHelper
  require 'json'

  # Returns full collection-level description (without container list)
  # api/collection/:collection_id[/:include_tree/:full]
  def collection
    @collection = Collection.find params[:id]
    @data = @collection ? collection_data(params) : {}
    if params[:pretty]
      render 'show'
    else
      if params[:callback]
        render :json => "#{params[:callback]}(#{@data.to_json});" 
      else
        render :json => @data.to_json
      end
    end
  end
  
  # Returns same as collection (above), but uses identifier type/value to find collection
  # api/collection_by_identifier/:identifier_type/:identifier_value(/:include_tree(/:full))
  def collection_by_identifier
    @collection = Collection.where(:identifier_value => params[:identifier_value], :identifier_type => params[:identifier_type]).first
    @data = @collection ? collection_data(params) : {}
    if params[:pretty]
      render 'show'
    else
      if params[:callback]
        render :json => "#{params[:callback]}(#{@data.to_json});" 
      else
        render :json => @data.to_json
      end
    end
  end
  
  
  # basic descriptive data for a collection (used for indexes, etc.)
  def collection_overview
    @collection = Collection.find params[:id]
    collection_data = @collection.unit_data(:basic => true)
    collection_data.delete_if { |k,v| v.blank? }
    if params[:pretty]
      @data = collection_data
      render 'show'
    else
      if params[:callback]
        render :json => "#{params[:callback]}(#{collection_data.to_json});" 
      else
        render :json => collection_data.to_json
      end
    end
  end
  
  
  # Returns collection structure/arrangement for use in navigation
  def collection_tree
    @collection = Collection.find params[:id]
    @tree = @collection.structure(params)
    if params[:pretty]
      @data = @tree
      render 'show'
    else
      if params[:callback]
        render :json => "#{params[:callback]}(#{@tree.to_json});" 
      else
        render :json => @tree.to_json
      end
    end
  end
  
  
  # Returns components for a collection. :level param can be used to specify maximum depth (default is to return all components at all levels)
  # api/collection_components/:collection_id/:component_id/:level
  def collection_components
    if !params[:component_id] || params[:component_id].to_i == 0
      @collection = Collection.find params[:id]
      @root = @collection
    else
      @component = Component.find params[:component_id]
      @root = @component
    end
    
    level = params[:level] ? params[:level].to_i : nil
    
    @components = @root.all_component_data(level)
    
    if params[:pretty]
      @data = @components
      render 'show'
    else
      if params[:callback]
        render :json => "#{params[:callback]}(#{@components.to_json});" 
      else
        render :json => @components.to_json
      end
    end
    
  end
  
  
  # Return all data available for a single component
  def component
    @component = Component.includes(:description,:access_term_associations).find params[:id]
    
    component_data = @component.unit_data
    component_data[:controlaccess] = @component.access_term_data
    component_data[:component_path] = @component.component_ancestors.map { |a| a.title }
    
    # include basic collection data
    component_data[:collection] = @component.collection.basic_unit_data
    component_data[:collection][:prefercite] = @component.collection.prefercite
    
    if !@component.has_children
      component_data[:image_count] = @component.total_captures
    end
    
    level = params[:level] ? params[:level].to_i : nil
    if level.nil? || level > 1
      component_data[:components] = @component.all_component_data(level)
    else
      component_data[:child_id] = []
      @component.children.each { |cc| component_data[:child_id] << cc.id }
    end
    
    component_data.delete_if { |k,v| v.blank? }
    if params[:pretty]
      @data = component_data
      render 'show'
    else
      if params[:callback]
        render :json => "#{params[:callback]}(#{component_data.to_json});" 
      else
        render :json => component_data.to_json
      end
    end
  end
  
  
  # Returns all image identifiers available for a single component
  def component_images
    @component = Component.find params[:id]
    @data = @component.capture_ids
    
    if params[:pretty]
      render 'show'
    else
      if params[:callback]
        render :json => "#{params[:callback]}(#{@data.to_json});" 
      else
        render :json => @data.to_json
      end
    end
  end
  
  
  def collection_list
    list = []
    total = Collection.where(:active => true).count
    
    # If 'simple' param is set to true, the list will only return id, title and dates, and will ignore pagination
    if params[:simple]
      @collections = Collection.where(:active => true).order(:origination)
    else
      params[:page] ||= 1
      params[:per_page] ||= 10
      @collections = Collection.includes(:description).where(:active => true).paginate(:page => params[:page].to_i, :per_page => params[:per_page]).order(:origination)
    end
    
    @collections.each do |c|
      collection_data = c.unit_data(:basic => true)
      collection_data[:abstract] = c.abstract.strip
      list << collection_data
    end
    
    @data = {:total => total, :list => list }
    
    if params[:pretty]
      render 'show'
    else
      if params[:callback]
        render :json => "#{params[:callback]}(#{@data.to_json});" 
      else
        render :json => @data.to_json
      end
    end
  end
  
end