class ContactsController < ApplicationController
  
  include ContactsHelper
  
  def compose
    
    # 'request', 'question' or 'feedback'
    @mode = params[:mode] || 'question'

    if params[:collection_id]
      @collection = Collection.find params[:collection_id]
    end
    
    if params[:org_unit_code]
      @org_unit_code = params[:org_unit_code].upcase
      @org_unit = OrgUnit.find_by_code @org_unit_code
      puts '@org_unit'
      puts @org_unit.inspect
    elsif params[:org_unit_id]
      @org_unit = OrgUnit.find params[:org_unit_id]
      @fieldsets = fieldsets(@org_unit.code)
      puts '@fieldsets'; puts @fieldsets.inspect
      # determine whether to ask user if they want to ask a question or request access
      @show_choice = @mode == 'request' ? false : request_materials_enabled(@org_unit.code)
      @org_unit_code = @org_unit ? @org_unit.code : nil
    end
    
    if @collection
      @request_subject = "the #{@collection.title}"
    elsif @org_unit
      @request_subject = "#{@org_unit.name_short} materials"
    else
      @request_subject = "materials"
    end
    
    
    if @mode == 'feedback'
      @feedback_fields = feedback_fields
    end
    
    @contact_fields = fieldsets(:default)
    
    # @message_data = {}

    @layout = params[:layout] == 'false' ? false : true


    render :layout => params[:layout] == 'false' ? false :  true


  end
  
  
  def deliver

    message_elements = field_config.keys
    
    @message_data = { :mode => params[:mode] }
    @message_data[:org_unit_id] = params[:org_unit_id]
    
    @message_data[:fields] = {}
    message_elements.each do |e|
      if params[e]
        puts e
        @message_data[:fields][e] = { :label => field_config[e][:label], :value => params[e] }
      end
    end

    @message_data[:send_auto_response] = false
    
    if @message_data[:org_unit_id]
      @org_unit = OrgUnit.find @message_data[:org_unit_id]
      @message_data[:to] = @org_unit.email

      #send the auto response if they are addressing an org unit
      @message_data[:send_auto_response] = true
      @message_data[:auto_response_text] = @org_unit.email_response_text
      @message_data[:org_unit_center] = @org_unit.center
      @message_data[:org_unit_short_name] = @org_unit.name_short
      @message_data[:org_unit_long_name] = @org_unit.name
      @message_data[:org_unit_url] = @org_unit.url
      @message_data[:org_unit_email] = @org_unit.email
    else
      @message_data[:to] = ADMIN_EMAIL
    end
        
    if params[:collection_id]
      @collection = Collection.find params[:collection_id]
      @message_data[:collection] = @collection.title
    end

      if request.env['HTTP_USER_AGENT']
        @message_data[:user_agent] = request.env['HTTP_USER_AGENT']
      end

    begin
      

      ContactMailer.contact_email(@message_data).deliver
      ContactMailer.response_email(@message_data).deliver

      redirect_to request.referrer
    rescue Exception => e
      puts e
      redirect_to request.referrer
    end
    
  end
  
  
end
