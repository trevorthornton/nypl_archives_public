class CollectionsController < ApplicationController
  
  require 'modules/delayed_solr_index.rb'

  include CollectionsHelper
  
  @@default_redirect = '/'
  @@path_to_tmp_folder = 'public/uploads/tmp/'
  
  before_filter :authenticate
  
  def index
    @page = params[:page] || 1
    @per_page = params[:per_page] || 30
    @sort = params[:sort] || 'created_at'
    @collections = Collection.includes(:org_unit).paginate(:page => @page, :per_page => @per_page).
      order(@sort == 'created_at' ? 'created_at desc' : @sort)
  end
  
  
  def show
    @collection = variable_collection_find
    @record = @collection
    if !@collection
      flash[:error] = 'Collection not found.'
			redirect_to 'collections'
			return
		else
		  @description = JSON.parse(@collection.description.data)
      @children = @collection.children
      @documents = @collection.documents
      @external_resources = @collection.external_resources
      @is_catalog = EadIngest.where(collection_id: @collection.id).count == 0 ? true : false
      @org = OrgUnit.find(@collection.org_unit_id)['code'].downcase
      @boost_queries = @collection.boost_queries ? JSON.parse(@collection.boost_queries) : []
	  end
	  case params[:format]
    when 'mods'
      render :xml => @collection.mods
    when 'mms_json'
      render :json => @collection.mms_json(url_for("http://"+request.host))
    else
      render
    end
  end

  
  def new

    p request.protocol.to_s + request.host.to_s   + ":" + request.port.to_s
    p request.protocol.to_s + request.host.to_s   + ":" + request.port.to_s
    p request.protocol.to_s + request.host.to_s   + ":" + request.port.to_s

    #grab org units
    @orgs = OrgUnit.select("id").select("code").select("name_short")
  
    possible_orgs = []
    @orgs.each do |o|
      possible_orgs << o['code'].downcase
    end

    @exiting_files = []

    Dir.glob(@@path_to_tmp_folder + '*.xml') do |rb_file|
      # do work on files ending in .rb in the desired directory
      #@exiting_files << 
      filename = rb_file.split(File::SEPARATOR)
      filename = filename[filename.length-1]
      matchData = filename.match(/[a-zA-Z]{3}[0-9]*/).to_s
      matchData  = matchData[3..-1]

      matchOrg = filename.match(/^[a-z]{3}/).to_s

      if !possible_orgs.include? matchOrg
        matchOrg = ''
      end



      @exiting_files << { "filename" => filename, "mssId" => matchData, "org" => matchOrg}

    end
    puts @exiting_files

  end
  
  
  def create


    if params['files']

      @orgs = OrgUnit.select("id").select("code").select("name_short")
    
      possible_orgs = []
      @orgs.each do |o|
        possible_orgs << o['code'].downcase
      end


      if !File.directory?(@@path_to_tmp_folder)
        FileUtils.mkpath @@path_to_tmp_folder
      end



      result = {"files" => []}

      params['files'].each do |file|
        if file.content_type == 'text/xml'
          path = @@path_to_tmp_folder + file.original_filename
          File.open(path, "wb") { |f| f.write(file.read) }

          #attempt to find the collection number if they put it in the file name
          matchData = file.original_filename.match(/[a-zA-Z]{3}[0-9]*/).to_s
          matchData  = matchData[3..-1]

          matchOrg = file.original_filename.match(/^[a-z]{3}/).to_s

          if !possible_orgs.include? matchOrg
            matchOrg = ''
          end


          result['files'] << { "name" => file.original_filename, "mssId" => matchData, "org" => matchOrg}

          render :json => result.to_json

        end 
      end
    end


  end
  
  
  def edit
    @collection = Collection.find params[:id]
    @record = @collection
    @update_type = params[:update_type]
    @boost_queries = @collection.boost_queries ? JSON.parse(@collection.boost_queries) : []
  end
  
  
  def update
    if params[:commit] != 'Cancel'
      
      @collection = Collection.find params[:id]
    
      # remove pdf finding aid (or not)
      if params[:collection][:remove_pdf_finding_aid] == '1'
        @collection.remove_pdf_finding_aid!
      elsif params[:collection][:remove_pdf_finding_aid]
        params[:collection].delete(:remove_pdf_finding_aid)
      end
      
      if params[:collection][:boost_queries]
        queries_array = params[:collection][:boost_queries].split(',')
        queries_array.each { |q| q.strip! }
        params[:collection][:boost_queries] = JSON.generate(queries_array)
      end
      
      if !params[:collection].blank?
        @collection.update_attributes(params[:collection])
      end
      
    end

    redirect_to session[:return_to]
  end
  
  
  def destroy
    
  end

  def ingest_ead_from_interface

    if params[:filename].blank? or params[:org_unit_id].blank? or params[:identifier_value].blank? or params[:identifier_type].blank?
      render :json => {"error" => true, "message" => 'Missing paramaters.'}
    else


      path = request.protocol + request.host.to_s + ":" + request.port.to_s + '/uploads/tmp/' + params[:filename]


      #check how many compos we got 
      component_count = File.open(@@path_to_tmp_folder + params[:filename].to_s).read().scan(/<\/c[0-9]{2}>/).count
      
      if params[:bnumber].blank? 
        data = { :tmp_file => true, :delete_url => request.protocol + request.host.to_s + ":" + request.port.to_s + '/collections/ingest/remove_tmp_ead/?filename=' + params[:filename],  :filename =>  params[:filename], :filepath => path, :org_unit_code => OrgUnit.find(9)['code'], :org_unit_id => params[:org_unit_id].to_i, :identifier_type => params[:identifier_type], :identifier_value => params[:identifier_value], :component_count => component_count}
      else
        data = { :bnumber  => params[:bnumber], :tmp_file => true, :delete_url => request.protocol + request.host.to_s + ":" + request.port.to_s + '/collections/ingest/remove_tmp_ead/?filename=' + params[:filename],  :filename =>  params[:filename], :filepath => path, :org_unit_code => OrgUnit.find(9)['code'], :org_unit_id => params[:org_unit_id].to_i, :identifier_type => params[:identifier_type], :identifier_value => params[:identifier_value], :component_count => component_count}
      end


      #Get the current status and see if we are already doing this one
      status = ingest_status(true)
      active_ids = []
      status.each do |s|
        active_ids << s[:id].to_i
      end

      if active_ids.include? params[:identifier_value].to_i
        render :json => {"error" => true, "message" => 'Already processing that EAD file.'}
      else


        #it is a new collection
        if Collection.find_by_identifier(params[:identifier_value]).nil?

          Collection.delay.create_from_ead(data)
          
        
        else

          #updaing  
          x = Collection.find_by_identifier(params[:identifier_value])          
          x.delay.update_from_ead(data)

          #delete the XML
          uri = URI.parse(request.protocol + request.host.to_s + ":" + request.port.to_s + '/collections/ingest/remove_tmp_ead/?filename=' + params[:filename])
          uri.delay.open


        end


        #queue up building the pdf
        uri = URI.parse(request.protocol + request.host.to_s.gsub("data.",'') + ":" + request.port.to_s + "/" + OrgUnit.find(9)['code'].downcase + '/' + params[:identifier_value] + '/pdf')
        uri.delay.open

        #is there a index job queued up or do we need to start one
        if Delayed::Job.where('handler like "%!ruby/struct:DelayedSolrIndex%" AND locked_at is NULL').blank? 
          Delayed::Job.enqueue DelayedSolrIndex.new('delta'), :priority => 2
        end
        



        render :json => {"error" => false, "message" => 'Hi there :)'}
      end



    end

  end

  def ingest_bnumber_from_interface

    if params[:bnumber].blank? or params[:org_unit_id].blank? or params[:identifier_value].blank? or params[:identifier_type].blank?
      render :json => {"error" => true, "message" => 'Missing paramaters.'}
    else


      data = { :bnumber => params[:bnumber].to_s, :org_unit_code => OrgUnit.find(9)['code'], :org_unit_id => params[:org_unit_id].to_i, :identifier_type => params[:identifier_type], :identifier_value => params[:identifier_value], :component_count => 0}


      #Get the current status and see if we are already doing this one
      status = ingest_status(true)
      active_ids = []
      status.each do |s|
        active_ids << s[:id].to_i
      end

      if active_ids.include? params[:identifier_value].to_i
        render :json => {"error" => true, "message" => 'Already processing that EAD file.'}
      else
        Collection.delay.create_from_catalog_record(data)

        #is there a index job queued up or do we need to start one
        if Delayed::Job.where('handler like "%!ruby/struct:DelayedSolrIndex%" AND locked_at is NULL').blank? 
          Delayed::Job.enqueue DelayedSolrIndex.new('delta'), :priority => 2
        end
        

        render :json => {"error" => false, "message" => 'Hi there :)'}
      end



    end

  end

  def ingest_status(internal=false)

    jobs=Delayed::Job.select("attempts").select("handler").select("last_error")

    results = []

    jobs.each do |d|

      this_result = {}

      id = d[:handler].to_s.match(/:identifier_value:\s[\'|\"]([0-9]*)[\'|\"]/i)
      filename = d[:handler].to_s.match(/:filepath:.*\/((.*\.xml))/i)
      component_count = d[:handler].to_s.match(/:component_count:\s([0-9]*)/i)
      org_unit_code = d[:handler].to_s.match(/:org_unit_code:\s([A-Z]{3})/i)
      bnumber = d[:handler].to_s.match(/:bnumber:\s(b[0-9]*)/i)

      if d[:locked_by].nil?
        is_locked = true
      else
        is_locked = false
      end
      
      if id

        this_result[:raw] = d
        
        id = id[1].to_i

        if filename
          filename = filename[1].to_s
          this_result[:filename] = filename
        else
          bnumber = bnumber[1].to_s
          this_result[:filename] = bnumber
        end

        attempts = d[:attempts].to_i

        this_result[:id] = id
        
        this_result[:attempts] = attempts
        this_result[:component_count] = component_count[1].to_i
        this_result[:org_unit_code] = org_unit_code
        this_result[:is_locked] = is_locked

        status = ""

        this_result[:status] = ""

        #see if there was an error
        if d[:last_error].nil?

          #no error figure out the status of the thang


          #is it in the collection table?
          if !Collection.find_by_identifier(id).nil?


              #get the number of components created
              db_id = Collection.find_by_identifier(id)[:id]
              count = Component.where(:collection_id => db_id).count

              if count > 0
                status = "Building Components (" + count.to_s + "/" + this_result[:component_count].to_s  + ")"
                this_result[:component_count_done] = count
              else
                status = "Building Collection"
              end
              


          else

            #nope, still waiting to process
            status = "Queued"

          end



        else

          status = "Error"

        end

        this_result[:status] = status
        results << this_result


      end
      

    end


    last_active =EadIngest.joins("inner join collections on ead_ingests.collection_id = collections.id").joins("inner join org_units on collections.org_unit_id = org_units.id").select(" ead_ingests.filename, ead_ingests.updated_at, collections.id, collections.identifier_value,collections.title, org_units.code").order("ead_ingests.id DESC").limit(25)
    last_active_catalog = CatalogImport.joins("inner join collections on catalog_imports.collection_id = collections.id").joins("inner join org_units on collections.org_unit_id = org_units.id").select("catalog_imports.bnumber, catalog_imports.updated_at, collections.id, collections.identifier_value,collections.title, org_units.code").order("catalog_imports.id DESC").limit(25)
    
    last_active_array = []

    last_active.each do |e|
      last_active_array << { "filename" => e[:filename],"identifier_value" => e[:identifier_value],"updated_at" => e[:updated_at],"title" => e[:title], "code" => e[:code], "dbId" => e[:id]}
    end

    last_active_catalog.each do |e|
      last_active_array << { "filename" => e[:bnumber],"identifier_value" => e[:identifier_value],"updated_at" => e[:updated_at],"title" => e[:title], "code" => e[:code], "dbId" => e[:id]}
    end

    #last_active_array = last_active_array.sort_by! { |hsh| hsh[:asdf] }

    last_active_array.sort_by! { |h| h['updated_at'] }
    last_active_array.reverse!


    if !internal
      render :json => {"active" => results, "previous" => last_active_array}
    else
      return results
    end

  end

  def remove_tmp_ead
    filename = params[:filename].to_s
    filename.gsub! '..', ''
    FileUtils.rm(@@path_to_tmp_folder + filename )
    render :json => {"results" => true}
  end

  def collection_exists

    x = Collection.find_by_identifier params[:id]
    if x.nil?
      render :json => {"results" => false}
    else
      render :json => {"results" => true}
    end

  end
  
  
end

class AsyncTask
  def run(url)
    open(url)
  end
  handle_asynchronously :run
end






