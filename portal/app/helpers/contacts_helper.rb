module ContactsHelper
  
  include ApplicationHelper
  
  def field_config
    { :name => {:type => :text, :label => 'Name' },
      :name_first => {:type => :text, :label => 'First name', :required => true},
      :name_last => {:type => :text, :label => 'Last name', :required => true},
      :address_street_1 => {:type => :text, :label => 'Address (line 1)', :required => true},
      :address_street_2 => {:type => :text, :label => 'Address (line 2)'},
      :city => {:type => :text, :label => 'City', :required => true},
      :state => {:type => :select, :label => 'State/province', :options => state_province_options, :default_option => 'NY'},
      :zip => {:type => :text, :label => 'Zip/postal code', :width => 10, :required => true},
      :email => {:type => :text, :label => 'Email', :required => true},
      :affiliation => {:type => :text, :label => 'Affiliation (organization)'},
      :title => {:type => :text, :label => 'Job title / Academic standing'},
      :reference => {:type => :textarea, :label => 'Professional reference',
        :description => "Please provide name and contact information of a person familiar with your project.
        If conducting personal/independent research, include contact information of a professional or
        personal reference and the nature of your relationship
        (may not be someone directly related to you, or with whom you share an address)."},
      :purpose => {:type => :select, :label => 'Research goal/purpose', :options => research_purpose_options },
      :research_topic => {:type => :text, :label => 'Research topic'},
      :abstract => {:type => :textarea, :label => 'Abstract',
        :description =>"Understanding your research subject, scope,and purpose allows the archivists to
        identify (other) pertinent collections for you and better prepare for your visit.
        Please provide a detailed description of your research project.
        If appropriate, specify the particular aspect of your project that you will be investigating with
        our collections. Also specify what you hope to find in the collection(s) you plan to consult
        (e.g, correspondence between particular individuals, meeting minutes from certain dates,
        or photographs of certain places)."},
      :prior_research => {:type => :textarea, :label => 'Prior research',
        :description =>"Research on this topic conducted, e.g., published sources examined, etc."},
      :body => {:type => :textarea, :label => 'How can we help you?', :required => true},
      :note => {:type => :textarea, :label => 'Notes/other information' },
      :collections => {:type => :textarea, :label => 'Collections of interest', :alt_label => 'Other collections of interest'},
      :visit_date => {:type => :text, :label => 'Date and length of your planned visit (if applicable)'},
      :feedback_body => { :type => :textarea, :label => nil, :rows => 10 },
      :terms_accepted => {:type => :check_box, :label => 'Terms accepted' }
    }
  end
  
  
  def fieldset_config(set)
    config = {}
    fieldsets = {
      :name => [:name_first,:name_last],
      :address => [:address_street_1, :address_street_2, :city, :state, :zip],
      :affiliation => [:affiliation, :title]
    }
    if !fieldsets[set]
      config[set] = field_config[set]
    else
      fieldsets[set].each { |n| config[n] = field_config[n] }
    end
    config
  end
  
  
  def fieldsets(org_unit_code)
    defaults = [:name, :email, :body]
    setlist = {
      'MSS' => { :sets => [:name, :email, :address, :affiliation, :reference, :purpose, :abstract, :collections, :visit_date],
        :required => [:reference, :purpose, :abstract, :collections] },
      'NYPLA' => { :sets => [:name, :email, :address, :affiliation, :reference, :purpose, :abstract, :collections, :visit_date],
        :required => [:reference, :purpose, :abstract, :collections] },
      'CPS' => { :sets => [:name, :email, :address, :affiliation, :purpose, :research_topic, :collections, :visit_date] },
      'BRG' => { :sets => [:name, :email, :address, :affiliation, :reference, :purpose, :abstract, :prior_research, :collections, :visit_date],
        :required => [:reference, :purpose, :abstract] },
      'DAN' => { :sets => [:name, :email, :address, :affiliation, :purpose, :research_topic, :collections, :visit_date] }
    }
    setlist[org_unit_code] ||= { :sets => defaults }
    sets = {}
    
    # get field configs
    setlist[org_unit_code][:sets].each do |k|
      sets[k] = fieldset_config(k)
      
      # process required fields
      required = setlist[org_unit_code][:required]
      if required
        sets.each do |k,v|
          v.each do |field,config|
            if required.include?(field)
              config[:required] = true
            end
          end
        end
      end
      
    end
    sets
  end
  
  
  def feedback_fields
    sets = {
      :feedback_body => field_config[:feedback_body],
      :name => field_config[:name],
      :email => field_config[:email]
    }
    sets[:email][:required] = nil
    sets
  end

  
  def field_output(field,config)
    output = ''
    output += "<div class='#{field}'>"
    
    if config[:label]
      if field == :collections && @collection
        config[:required] = nil
        label_text = config[:alt_label] + (config[:required] ? ' *' : '')
      else
        label_text = config[:label] + (config[:required] ? ' *' : '')
      end
      output += "<label for='#{field.to_s}'>#{label_text}</label>"
    end
    
    if config[:description]
      output += "<div class='field-description'>#{config[:description]}</div>"
    end
    
    field_class = config[:required] ? 'required' : nil
    case config[:type]
    when :text
      output += text_field_tag(field, '', :class => field_class)
    when :textarea
      rows = config[:rows] || 5
      # output += text_area(field.to_s, '', :rows => rows, :class => field_class)
      output += text_area_tag(field, '', :rows => rows, :class => field_class)
    when :select
      if config[:options]
        output += select_tag(field, options_for_select(config[:options],config[:default_option]), :class => field_class)
      end
    end
    output += "</div>"
    output
  end
  
  
  def fieldset_output(fieldset,config)
    output = ''
    if config.length > 1
      output += "<div class='#{fieldset.to_s}-fields'>"
    end    
    case fieldset
    when :address
            
      config.each do |field,field_config|
        if ![:state,:zip].include?(field)
          output += field_output(field,field_config)
        end
      end
      
      output += '<div class="state-zip-fields">'
      [:state,:zip].each { |f| output += field_output(f,config[f]) }
      output += '</div>'
    else
      config.each do |field,field_config|
        output += field_output(field,field_config)
      end
    end
    if config.length > 1
      output += "</div>"
    end 
    output
    
  end
  
  
  
  def terms_output(org_unit_id=nil)
    org_unit = org_unit_id ? (OrgUnit.find org_unit_id) : nil
    output = "<div class='terms-fields'>"
    accept_text = ""
    basic_accept_text = "I understand that submitting this form does not guarantee access
      to specified collections nor access to collections on specific dates."
    
    if org_unit
      rules = org_unit.access_rules
      if !rules.blank?
        output += "Rules for using #{ org_unit.name_short } collections"
        output += '<div class="access-rules">'
        output += rules
        output += "</div>"
        accept_text += "I have read the Rules stipulated above,
          and agree to adhere to these and any other relevant instructions of NYPL staff."
      end
    end
    
    accept_text += " " + basic_accept_text
    accept_text.strip!
    output += '<div class="checkbox">'
      output += check_box_tag(:terms_accepted, value = "1", checked = false)
      output += " " + label_tag(:terms_accepted, accept_text, :class => 'accept-text')
      output += "</div>"
    output += "</div>"
  end
  
  
  def research_purpose_options
    options = ["Book", "Conference paper", "Course paper", "Dissertation", "Journal article",
      "Documentary", "Genealogy research", "Master's thesis", "Personal research", "Other"]
    options.each { |o| o = [o,o] }
    puts options.inspect;
    return options
  end
  
  
  def state_province_options
    [["Alabama","AL"],
    ["Alaska","AK"],
    ["Arizona","AZ"],
    ["Arkansas","AR"],
    ["California","CA"],
    ["Colorado","CO"],
    ["Connecticut","CT"],
    ["Delaware","DE"],
    ["District Of Columbia","DC"],
    ["Florida","FL"],
    ["Georgia","GA"],
    ["Hawaii","HI"],
    ["Idaho","ID"],
    ["Illinois","IL"],
    ["Indiana","IN"],
    ["Iowa","IA"],
    ["Kansas","KS"],
    ["Kentucky","KY"],
    ["Louisiana","LA"],
    ["Maine","ME"],
    ["Maryland","MD"],
    ["Massachusetts","MA"],
    ["Michigan","MI"],
    ["Minnesota","MN"],
    ["Mississippi","MS"],
    ["Missouri","MO"],
    ["Montana","MT"],
    ["Nebraska","NE"],
    ["Nevada","NV"],
    ["New Hampshire","NH"],
    ["New Jersey","NJ"],
    ["New Mexico","NM"],
    ["New York","NY"],
    ["North Carolina","NC"],
    ["North Dakota","ND"],
    ["Ohio","OH"],
    ["Oklahoma","OK"],
    ["Oregon","OR"],
    ["Pennsylvania","PA"],
    ["Rhode Island","RI"],
    ["South Carolina","SC"],
    ["South Dakota","SD"],
    ["Tennessee","TN"],
    ["Texas","TX"],
    ["Utah","UT"],
    ["Vermont","VT"],
    ["Virginia","VA"],
    ["Washington","WA"],
    ["West Virginia","WV"],
    ["Wisconsin","WI"],
    ["Wyoming","WY"],
    ["Alberta","AB"],
    ["British Columbia","BC"],
    ["Manitoba","MB"],
    ["New Brunswick","NB"],
    ["Newfoundland/Labrador","NL"],
    ["Nova Scotia","NS"],
    ["Northwest Territories","NT"],
    ["Nunavut","NU"],
    ["Ontario","ON"],
    ["Prince Edward Island","PE"],
    ["Quebec","QC"],
    ["Saskatchewan","SK"],
    ["Yukon","YT"]]
  end
  
end
