class ContactMailer < ActionMailer::Base

  default :sender => 'archivescontact@nypl.org'

    
  def contact_email(message_data)
    @message_data = message_data
    
    if @message_data[:fields][:email]
      email = @message_data[:fields][:email][:value]
    else
      email = nil
    end
    

    sender = email || 'archivescontact@nypl.org'
    if @message_data[:fields][:name]
      name = @message_data[:fields][:name][:value]
    elsif @message_data[:fields][:name_first][:value] && @message_data[:fields][:name_last][:value]
      name = @message_data[:fields][:name_first][:value] + " " + @message_data[:fields][:name_last][:value]
    else
      name = 'archives.nypl.org user'
    end
 

    if (email == 'archivescontact@nypl.org')

      mail(to: 'archivescontact@nypl.org', from: sender, subject: "archives.nypl.org - Message from #{name}")

    else

      mail(to: @message_data[:to], from: sender, subject: "archives.nypl.org - Message from #{name}")

    end

    

  
  end


  def response_email(message_data)

    @message_data = message_data

    if (@message_data[:send_auto_response])


      if (@message_data[:auto_response_text])

        @auto_response_text = @message_data[:auto_response_text]

      else


        if (@message_data[:org_unit_center] == 'SASB')
          @org_unit_location = ' at The New York Public Library'
        elsif (@message_data[:org_unit_center] == 'LPA') 
          @org_unit_location = ' at The New York Public Library for the Performing Arts'
        else
          @org_unit_location = ''
        end

      end

      if @message_data[:fields][:email]
        email = @message_data[:fields][:email][:value]
      else
        email = nil
      end

      mail(to: email, from: @message_data[:org_unit_email], subject: "archives.nypl.org - We have received your request.")

    else
      puts "No auto response"
    end 

  end

end

    

