class CollectionsController < ApplicationController
  
  include CollectionsHelper

  @@default_redirect = '/'

  @@crawler_agents = ['Googlebot','bingbot','Yahoo! Slurp','Ask Jeeves','Baiduspider','Yandex']

  
  rescue_from 'ActiveRecord::RecordNotFound' do |exception|
    flash[:error] = "Collection not found"
    puts exception
    redirect_to @@default_redirect
  end


  def index
    
  end


  def show
    
    if params[:format] == 'json'
      require 'json'
    end
    
    @collection = variable_collection_find
    if !@collection
      flash[:error] = 'Collection not found.'
			redirect_to @@default_redirect
		else
		  @org_unit = @collection.org_unit
      @collection_data_json = @collection.collection_response.desc_data
      @collection_structure_json = @collection.collection_response.structure
      #count the number of compoents
      @collection_component_count = Component.where("collection_id = ?", @collection['id']).count
    
      # @display_elements = {}
      # description_elements.each { |o| @display_elements[o] = send(o) }
      @display_sections = {}
      
      case params[:format]
      when 'json'
        render :json => @collection_data_json
      when 'xml'
        render :xml => @collection.ead

      when 'newpdf'
        pdf_url = @collection.pdf_recreate
        pdf_url = request.protocol + request.host_with_port + pdf_url 

        redirect_to pdf_url

        
      when 'pdf'


        if !@collection.pdf_finding_aid.blank?
          pdf_url = request.protocol + request.host_with_port + @collection.pdf_finding_aid_url
          puts pdf_url
          redirect_to pdf_url
        else


          #does it have components
          #if  @collection_component_count > 0
            pdf_url = @collection.pdf
            pdf_url = request.protocol + request.host_with_port + pdf_url
            redirect_to pdf_url 
          #else
          # redirect_to show_redirect
          #end

          
        end





      else
        @collection_data = JSON.parse(@collection_data_json)

        # @pdf_finding_aid = pdf_finding_aid(@collection_data)
        # puts @collection_data['physdesc'].inspect

        @render_container_list = false


        @@crawler_agents.each do |u|

          if request.user_agent.downcase.include? u.downcase
            
            @render_container_list = true
            @components = Component.joins(:component_response).where("collection_id = ?", @collection['id']).order("component_responses.component_id ASC").select("desc_data")

            break
          end


        end


        render
      end
		end

  end

  def container_list
    @collection = Collection.find params[:id]
  end


  def container_list_page
    @limit = 2000
    @offset = @limit * params[:page].to_i

    @components = Component.joins(:component_response).where("collection_id = ?", params[:id]).order("components.load_seq ASC").limit(@limit).offset(@offset).select("desc_data, digital_objects")

    #wrap it in json formating

    @output = '{"page":[' + @components.map { |f| (f.digital_objects != nil)  ?  (f.desc_data[0..f.desc_data.length-2] + "," + f.digital_objects[1..f.digital_objects.length]) : f.desc_data  }.join(',') + "]}"

    render :text => @output, :content_type => "application/json"
  end
  
  
end
