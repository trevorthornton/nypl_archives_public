module PdfExport

  class PdfFile
    
    require 'prawn'
    require 'prawn/layout'
    require 'fileutils'
    include ApplicationHelper
    include OrgUnitsHelper



    @@path = 'public/uploads/collection/generated_finding_aids'

    @document = nil

    @@page_height = 792
    @@page_width = 612

    @@final_path = ''

    #what do do with each span data, make it normal, italicized or bold
    @@spans_normal = ['address','addressline','archref','bibref','bibseries','date','edition','expan','imprint','note','num','subarea','persname','famname','corpname','genreform','geogname','name','subject','occupation', 'chronlist', 'chronitem', 'eventgrp','event']
    @@spans_italicize = ['title','emph']
    @@spans_bold = ['abbr']

    @@spans_normal_regex = nil
    @@spans_italicize_regex = nil
    @@spans_bold_regex = nil


    def return_path()

      return @@final_path 

    end



    def initialize(options = {})


      validate_dirs()

      generate = true


      #build the regexes we're going to use.
      @@spans_normal_regex = Regexp.new "<span\sclass\=[\"\'](" +  @@spans_normal.join('||')  + ")[\"\']>(.*?)<\/span>", Regexp::MULTILINE || Regexp::IGNORECASE 
      @@spans_italicize_regex = Regexp.new "<span\sclass\=[\"\'](" +  @@spans_italicize.join('||')  + ")[\"\']>(.*?)<\/span>", Regexp::MULTILINE || Regexp::IGNORECASE 
      @@spans_bold_regex = Regexp.new "<span\sclass\=[\"\'](" +  @@spans_bold.join('||')  + ")[\"\']>(.*?)<\/span>", Regexp::MULTILINE || Regexp::IGNORECASE 


      

      #collect the collection information
      @collection = Collection.includes(:description, :org_unit, :access_term_associations).find options[:collection_id]
      if @collection
        @data = JSON.parse(@collection.response.desc_data)

        @title = ""
        if @data['title']
          @title = @data['title']
        end
        #page size is 612.00 x 792.00

        filename = @data['org_unit_code'].downcase + @data['identifier_value'].to_s + '.pdf'
        full_path = @@path + '/' + filename


        if File.exist?(full_path)
          #it exists, does it have a date older than the current modified date?
          if (File.mtime(full_path).to_i < @collection.response.updated_at.to_datetime.to_i)
            generate = true
          else
            generate = false
          end
        else
          generate = true
        end

        #DEBUGGGG
        #generate = true


        if options[:nocache]
          generate = true
        end


        if generate



          @document = Prawn::Document.new(:margin => [72, 72, 72, 82])


          #always build the overview


          buiild_overview()


          #do we have a container list to render?
          @components = Component.joins(:component_response).where("collection_id = ?", options[:collection_id]).order("components.load_seq ASC").select("desc_data")


          if @components.length > 0
            build_detail()
          end

          #add in the page number and header
          build_header_footer()


          #render the file
          @document.render_file full_path




        end


        @@final_path = '/uploads/collection/generated_finding_aids/' + filename


        


      end


      

      #pgnum = @document.page_count()

      #@document.number_pages pgnum.to_s, { :start_count_at => 0, :page_filter => :all, :at => [50, 0], :align => :right, :size => 14 }

      #puts @document.page_count()


      



    end


    def validate_dirs()

      if !File.directory?(@@path)
        FileUtils.mkpath @@path
      end
    end



    def return_pdf_markup(text = "")

        
      text = text.gsub(/<p>(.*?)<\/p>/im, '\1' + "\n\n")
      text = text.gsub(/<blockquote>(.*?)<\/blockquote>/im, '\1' + "\n")

      text = text.gsub(@@spans_italicize_regex, '<i>\2</i>')
      text = text.gsub(@@spans_bold_regex, '<b>\2</b>')
      text = text.gsub(@@spans_normal_regex, '\2')   


      #  #special lists
      text = text.gsub(/<ul class=[\"\']chronlist[\"\']>(.*?)<\/ul>/im, '\1' + "\n")

      text = text.gsub(/<ul class=[\"\']list[\"\']>(.*?)<\/ul>/im, '\1' + "\n")

      #  #replace all lists
      text = text.gsub(/<ul>(.*?)<\/ul>/mi, '\1' + "\n")
      text = text.gsub(/<ol>(.*?)<\/ol>/mi, '\1' + "\n")

      #  #special list items
      text = text.gsub(/<li class=["']chronitem["']>(.*?)<\/li>/im, '\1' + "\n")

      

      #  #replace all list items
      text = text.gsub(/<li>(.*?)\<\/li>/mi, '\1' + "\n")


      #special headers
      text = text.gsub(/<div\sclass\=[\"\']head[\"\']>(.*?)<\/div>/im, "\n" + '<b>\1</b>' + "\n")

      #special headers
      #text = text.gsub(/<div\sclass\=[\"\']note[\"\']>(.*?)<\/div>/imx, '(\1)')

      #all divs
      text = text.gsub(/<div\sclass\=[\"\'](.*?)[\"\']>(.*?)<\/div>/im, '\2' + "\n")

    

      text = text.gsub(/<date>(.*?)<\/date>/im, '\1')
      text = text.gsub(/<dao>(.*?)<\/dao>/im, '\1')
      text = text.gsub(/<daodesc>(.*?)<\/daodesc>/im, '\1')
      text = text.gsub(/<daogrp>(.*?)<\/daogrp>/im, '\1')
      text = text.gsub(/<daoloc>(.*?)<\/daoloc>/im, '\1')
      text = text.gsub(/<ref>(.*?)<\/ref>/im, '\1')
      text = text.gsub(/<refloc>(.*?)<\/refloc>/im, '\1')
      text = text.gsub(/<ptr>(.*?)<\/ptr>/im, '\1')
      text = text.gsub(/<ptrgrp>(.*?)<\/ptrgrp>/im, '\1')
      text = text.gsub(/<ptrloc>(.*?)<\/ptrloc>/im, '\1')
      text = text.gsub(/<extptr>(.*?)<\/extptr>/im, '\1')
      text = text.gsub(/<extptrloc>(.*?)<\/extptrloc>/im, '\1')
      text = text.gsub(/<ptrgrp>(.*?)<\/ptrgrp>/im, '\1')
      text = text.gsub(/<extref>(.*?)<\/extref>/im, '\1')
      text = text.gsub(/<extrefloc>(.*?)<\/extrefloc>/im, '\1')
      text = text.gsub(/<resource>(.*?)<\/resource>/im, '\1')
      text = text.gsub(/<linkgrp>(.*?)<\/linkgrp>/im, '\1')
      text = text.gsub(/<arc>(.*?)<\/arc>/im, '\1')

      text = text.gsub(/<emph>(.*?)<\/emph>/im, '<b>\1</b>')

         #  text = text.gsub(/<div\sclass\=[\"\']series\-title[\"\']>(.*?)<\/div>/, '<b>\1</b>')


         #  text = text.gsub(/<p\sclass\=\"list\-head\">/, '')
         #  text = text.gsub(/<p\sclass\=\'list\-head\'>/, '')



         #  text = text.gsub(/<span\sclass\=\"date\">(.*?)<\/span>/m,  '<b>\1</b>')

         #  

      text = text.gsub("/p>","\n")
      text = text.gsub("p>","\n")   

      text = text.gsub("/li>","\n")
      text = text.gsub('ul class="list">',"\n")   
      text = text.gsub("li>","\n")


        text
    end




    def buiild_overview()

      #@document.stroke_axis

      #@document.rectangle [100,100], 10, 10
     # @document.fill
     #@document.stroke_axis()
     date_statement = ""



     @document.font "Helvetica"
     @document.font_size 10

      @document.bounding_box([-15, 792-115], :width => 612-135, :height => 200) do
        @document.fill_color "f5f5f5"
        @document.fill_rectangle [0, 200], 612-135, 200    
        @document.stroke_bounds
      end

      @document.fill_color "000000"
      @document.bounding_box([-5, 792-120], :width => 612-135, :height => 200) do

        @document.image "app/assets/images/pdf_logo.png", :width => 51 

        @document.font_size 16
        @document.text_box "The New York Public Library", :at => [60, 190]
        @document.font_size 16
        @document.text_box @collection.org_unit.name, :at => [60, 170]


        @document.font_size 10

        @document.move_cursor_to 125
        @document.text "Guide to the"
        @document.move_down 2
        @document.font_size 14
        @document.text @data['title'], :style => :bold
        @document.font_size 12

        

        if (@data['date_statement'])
          @document.text @data['date_statement']
          date_statement = ", " +  @data['date_statement']
        end
        if (@data['call_number'])
          @document.text @data['call_number']
        end
        @document.move_down 12
        @document.font_size 10

        if (@data['sponsor'])
          @data['sponsor'].each do |s|
            if (s['value']) 
              @document.text s['value'].gsub(/<\/?[^>]+>/, '')
            end
          end
        end


        if (@data['processinfo'])


          #there is more than 1 processing note, the last one is the likely created by
          if @data['processinfo'].length > 1
            created_by = @data['processinfo'][@data['processinfo'].length-1]['value']
          else
            created_by = @data['processinfo'][0]['value']
          end

    

          #does it not contain combiled by but contains a semi?
          if !created_by.downcase.include? 'compiled by' and created_by.include? ';'

            created_by = created_by.split(';')

            #if @data['processinfo'].length > 1
            #  @data['processinfo'][@data['processinfo'].length]['value'] = created_by[1]
            #else
            #  @data['processinfo'][0]['value'] = created_by[1]
            #end

            if !created_by[0].downcase.include? 'processed by'
              @document.text 'Compiled by ' + created_by[0].gsub(/<\/?[^>]+>/, '') +'.'
            else
              @document.text created_by[0].gsub(/<\/?[^>]+>/, '') +'.'
            end
          else

            @document.text created_by.gsub(/<\/?[^>]+>/, '')

          end









        end



      end

      #Summary Headers
      @document.move_down 12
      @document.font_size 12
      @document.text "Summary", :style => :bold
      @document.move_down 12


      #summary fields
      summary_fields = [

        #these are all the fields that will appear in the overview
        #the title is the diaplyname
        #field is the json label
        #big meeans if it should have a inline title or a new line after title (like Creator history)

        {"title"=>"Creator", "field"=>"origination", "big"=> false, "allowHtml"=> false },
        {"title"=>"Title", "field"=>"title", "big"=> false, "allowHtml"=> false },
        {"title"=>"Size", "field"=>"extent_statement", "big"=> false, "allowHtml"=> false },
        {"title"=>"Source", "field"=>"acqinfo", "big"=> false, "allowHtml"=> false },
        {"title"=>"Accruals", "field"=>"accruals", "big"=> false, "allowHtml"=> false },
        {"title"=>"Appraisal", "field"=>"appraisal", "big"=> false, "allowHtml"=> false },
        {"title"=>"Abstract", "field"=>"Abstract", "big"=> false, "allowHtml"=> false },
        {"title"=>"Access", "field"=>"standard_access_note", "big"=> false, "allowHtml"=> false },
        {"title"=>"Physical Location", "field"=>"physloc", "big"=> false, "allowHtml"=> false },
        {"title"=>"Conditions Governing Access", "field"=>"accessrestrict", "big"=> false, "allowHtml"=> false },
        {"title"=>"Conditions Governing Use", "field"=>"userestrict", "big"=> false, "allowHtml"=> false },
        {"title"=>"Legal Status", "field"=>"legalstatus", "big"=> false, "allowHtml"=> false },
        {"title"=>"Physical Characteristics and Technical Requirements", "field"=>"phystech", "big"=> false, "allowHtml"=> false },
        {"title"=>"Alternative Form Available", "field"=>"altformavail", "big"=> false, "allowHtml"=> false },
        {"title"=>"Location of Originals", "field"=>"originalsloc", "big"=> false, "allowHtml"=> false },
        {"title"=>"Other Finding Aid", "field"=>"otherfindaid", "big"=> false, "allowHtml"=> false },
        {"title"=>"Preferred citation", "field"=>"prefercite", "big"=> false, "allowHtml"=> false },
        {"title"=>"Language of the Material", "field"=>"langmaterial", "big"=> false, "allowHtml"=> false },
        {"title"=>"Other Descriptive Data", "field"=>"odd", "big"=> false, "allowHtml"=> false },
        {"title"=>"Material Specific Details", "field"=>"materialspec", "big"=> false, "allowHtml"=> false },
        {"title"=>"Processing note", "field"=>"processinfo", "big"=> false, "allowHtml"=> false },
        {"title"=>"Creator History", "field"=>"bioghist", "big"=> true, "allowHtml"=> true },
        {"title"=>"Custodial History", "field"=>"custodhist", "big"=> true, "allowHtml"=> true },
        {"title"=>"Scope and Content Note", "field"=>"scopecontent", "big"=> true, "allowHtml"=> true },
        {"title"=>"Arrangement", "field"=>"arrangement", "big"=> false, "allowHtml"=> false },
        {"title"=>"Related Materials", "field"=>"relatedmaterial", "big"=> false, "allowHtml"=> false }


      ]


      #check the orgination role
      if (@data['origination_term'])
        if (@data['origination_term'][0])
          if (@data['origination_term'][0]['role'])
            summary_fields[0]['title'] = @data['origination_term'][0]['role'].split.map(&:capitalize).join(' ')
          end
        end
      end




      summary_fields.each do |a_field|  

        inline_title = ""

        #is it an array type of data
        if (@data[a_field['field']].kind_of?(Array))

          data = ""
          @data[a_field['field']].each do |s|   

            if (s['value'])    



              #special cases


              #remove the scopecontent
              if a_field['field'] == 'scopecontent'
                if s['type']
                  next if s['type'] == 'arrangement'
                end
              end



              if a_field['allowHtml']
                data = data + return_pdf_markup(s['value']) + ' '
              else
                data = data + s['value'].gsub(/<\/?[^>]+>/, '') + ' '
              end


              
            end
          end


          if data != ""
            if (data[data.length-1] == ',')
              data = data[0, data.length-1]
            end
          end


          if data != ""

            if (a_field['big'])
              @document.move_down 4
              @document.font_size 12
              @document.text a_field['title'], :style => :bold        
              @document.font_size 10
            else
              inline_title = "<b>" + a_field['title'] + ":</b>  "
            end
            

            @document.font_size 10

            #if a_field['allowHtml']
            #  @document.text inline_title  + data, :inline_format => true, :leading => 1
            #else
            @document.text inline_title  + data, :inline_format => true, :leading => 1
            #end
            
            @document.move_down 12
          end

        end



        #is it an literal type of data
        if (@data[a_field['field']].kind_of?(String))

          if (a_field['big'])
            @document.move_down 4
            @document.font_size 12
            @document.text a_field['title'], :style => :bold        
            @document.font_size 10
          else
            inline_title = "<b>" + a_field['title'] + ":</b>  "
          end
            
          @document.font_size 10
          if a_field['allowHtml']
            @document.text @data[a_field['field']]
          else
            @document.text inline_title  + @data[a_field['field']], :inline_format => true, :leading => 1
          end
          @document.move_down 12



        end






      end





     # @document.column_box([0, @document.cursor], :columns => 2, :width => @document.bounds.width) do
      if @data['controlaccess']

        @document.move_down 12
        @document.font_size 12
        @document.text "Key Terms", :style => :bold
        @document.move_down 12

        #classification of the terms into display labels
        terTitles = { "name" => "Names", 
                      "subject" => "Subjects", 
                      "geogname" => "Geographic Names", 
                      "genreform" => "Genre/Physical Characteristic",
                      "title" => "Titles",
                      "occupation" => "Occupations"
                    }


          @data['controlaccess'].each_with_index do |(key,value),index| 

          #just incase
          if terTitles[key] == nil
            terTitles[key] = "Terms"
          end

          @document.font_size 10
          @document.text terTitles[key], :style => :bold

          value.each do |value|

            @document.text value['term']

          end
          @document.move_down 12


        end
      end

     # end

     #save the page the overview ends on
     @overview_ends_on_page = @document.page_count()


    end



    def build_detail()

      @document.start_new_page(:margin => [72, 72, 72, 72])

      @document.font_size 12
      @document.text "Container List", :style => :bold
      @document.move_down 12

      @document.font_size 10


      table_data = []

      old_page = @document.page_count()


      active_level = { "1" => "", "2" => "", "3" => "", "4" => "", "5" => "", "6" => "", "7" => ""}


      @components.each do |c|

        @data = JSON.parse(c.desc_data)


        hasOrigination = (@data['origination']) ? true : false
        hasContainer = (@data['container']) ? true : false
        hasDigitalAsset = (@data['image']) ? true : false
        hasUnitid= (@data['unitid']) ? true : false      



        field_list = ['title','date_statement','extent_statement','abstract','origination','controlaccess','bioghist','scopecontent','note','physloc','arrangement','accessrestrict','arrangement','appraisal','langmaterial', 'odd']

        # title = (@data['title']) ? @data['title'] : "";
        # dateStatement = (@data['date_statement']) ? @data['date_statement'] : ""
        # extentStatement = (@data['extent_statement']) ? @data['extent_statement'] : ""
        # abstract = (@data['abstract']) ? @data['abstract'] : "" 
        # origination = (@data['origination']) ? @data['origination'] : "" 
        # controlaccess = (@data['controlaccess']) ? @data['controlaccess'] : ""     
        # bioghist = (@data['bioghist']) ? @data['bioghist'] : ""
        # scopecontent = (@data['scopecontent']) ? @data['scopecontent'] : ""
        # note = (@data['note']) ? @data['note'] : ""
        # physloc  = (@data['physloc ']) ? @data['physloc '] : ""
        # arrangement = (@data['arrangement']) ? @data['arrangement'] : ""
        # accessrestrict = (@data['accessrestrict']) ? @data['accessrestrict'] : ""
        # arrangement = (@data['arrangement']) ? @data['arrangement'] : ""
        # appraisal = (@data['appraisal']) ? @data['appraisal'] : ""
        # langmaterial = (@data['langmaterial']) ? @data['langmaterial'] : ""
        # odd = (@data['appraisal']) ? @data['odd'] : ""





        #controle Access terms?
        # if @data['controlaccess']


        #     displayControlaccess = '';

        #     controlaccess.each do 
        #     _.each(controlaccess, function(s, sIndex) { 

        #         _.each(s, function(t, tIndex) { 

        #           var extra = '';

        #           if (t.role){
        #             extra = "&nbsp(" + t.role + ")";
        #           }

        #           displayControlaccess += '<a title="' + sIndex + '/' + t.type +'" href="/controlaccess/' + t.id + '?term=' + encodeURIComponent(t.term) +  '">' + t.term  + extra + '</a>&nbsp;';

        #         });


        #     });
        # end



        #build fields 

        field_values = {}

        field_list.each do |i|

          if (@data[i])

            field_values[i] = ""


            if @data[i].kind_of?(Array)

              @data[i].each do |v|

                if v['value']
                  field_values[i] = field_values[i] + v['value']
                end

              end

            end

            if @data[i].kind_of?(String)
              field_values[i] = @data[i]
            end

            if @data[i].kind_of?(Hash)

              @data[i].each do |v|
                v.each do |h|
                  if h.kind_of?(Array) 
                    h.each do |x|
                      if x['term']
                        field_values[i] = field_values[i] + x['term']
                      end
                      if x['role']
                        field_values[i] = field_values[i] + ' (' + x['role'] + ')'
                      end
                    end                  
                  end                               
                end
              
              end



            end




          end

        end


        @displayContainerTypeFull = ''


        if (hasContainer)

          displayContainerType = ''
          displayContainerValue = ''
          

          @data['container'].each do |c|


            if c['type']
              displayContainerType = c['type'][0] + '. '
            end

            if c['value']
              displayContainerValue = c['value']
            end

            @displayContainerTypeFull = @displayContainerTypeFull  + displayContainerType + displayContainerValue + ' '

          end

        else
         

          #there is no container
          if hasUnitid

            

            @data['unitid'].each do |u|

              if (u['type'])

                if (u['type'] != "local_mss" && u['type']!= "local_barcode" &&  u['type'] != nil)                 
                  if (u['value'])
                    @displayContainerTypeFull = @displayContainerTypeFull + u['value']
                  end
                end

              else

                  if (u['value'])

                    if is_number?(u['value'])

                      if (u['value'].to_i < 20000)
                        @displayContainerTypeFull = @displayContainerTypeFull  + u['value']
                      end

                    else

                      @displayContainerTypeFull = @displayContainerTypeFull  + u['value']

                    end

                     


                  end

              end 
            end

          end

        end

        if @displayContainerTypeFull.length > 30
          container_align = :center
        else
          container_align = :right
        end

        @displayContainerTypeFull = '<font size="8">' + @displayContainerTypeFull + '</font>'





        #title



        #indent
        indent = @data['level_num'].to_i * 6
        
        content = ''


        if field_values['title']
          content = content + field_values['title']
        end

        if field_values['date_statement']
          content = content + ' <font size="8">' + field_values['date_statement'] + '</font>'
        end

        if field_values['extent_statement']
          content = content + ' <font size="8">(' + field_values['extent_statement'] + ')</font>'
        end

        #these are justthe laundry list of other possible fields to put into the compoenent description
        fields = ['abstract','controlaccess','bioghist','scopecontent','note','physloc','arrangement','accessrestrict','arrangement','appraisal','langmaterial', 'odd']

        fields.each do |f|

          if field_values[f]
            content = content + "\n" + ' <font size="8">' + return_pdf_markup(field_values[f]) + '</font>'
          end

        end

        if (field_values['origination'])
          content =  ' <font size="8"><i>' +  return_pdf_markup(field_values['origination']) +'</i></font>' + "\n" + content
        end





        table_data << [Prawn::Table::Cell::Text.new( @document, [0,0], :content => @displayContainerTypeFull, :inline_format => true, :align => container_align, :padding => 5, :padding_right => 5, :padding_bottom => 0, :padding_top => 4), Prawn::Table::Cell::Text.new( @document, [0,0], :content => content, :inline_format => true, :padding => 5, :padding_left => indent, :padding_bottom => 0, :padding_top => 4)]
        @document.table(table_data, :column_widths => [75, 353], :cell_style => {:border_width => 0})

        table_data = []

        active_level[@data['level_num'].to_s] = field_values['title']

        if !active_level[@data['level_num'].to_s]

          active_level[@data['level_num'].to_s] = field_values['date_statement']

        end



        if (old_page != @document.page_count())
          old_page = @document.page_count()

          this_level = @data['level_num'].to_i


          if this_level> 1

            1.upto(this_level-1) do |i|

              @document.font_size 8
              #@document.text_box(active_level[ (@data['level_num'].to_i - i).to_s] + i.to_s, :at => [80 + ((@data['level_num'].to_i - i) *6), 645 + (10*i)])
              if active_level[(this_level-i).to_s]
                @document.text_box(active_level[(this_level-i).to_s] + " (cont.)", :at => [73 + ((this_level-i) *6), 645 + (10*i)])
              else
                @document.text_box("?????" + " (cont.)", :at => [73 + ((this_level-i) *6), 645 + (10*i)])
              end

              
              @document.font_size 10

            end



          end

          #@document.text "SHIT NEW PAGE"
        end

      end


      


    end

    def build_header_footer()

      roman = ['i','ii','iii','iv','v','vi','vii','viii','ix','x','xi','xii','xiii','xiv','xv','xvi','xvii','xviii','xix','xx','xxi','xxii','xxiii','xxiv','xxv','xxvi','xxvii','xxviii','xxix','xxx','xxxi','xxxii','xxxiii','xxxiv','xxxv','xxxvi','xxxvii','xxxviii','xxxix','xl']

      @document.page_count.times do |i|
        @document.go_to_page(i+1)

        #are we in the overview or the detail
        

          @document.bounding_box([485, -20], :width => 25, :height => 10) do



            if i <= @overview_ends_on_page -1
              @document.text_box(roman[i])
            else
              @document.text_box((i-@overview_ends_on_page+1).to_s)
            end

          end

          if i > @overview_ends_on_page -1
            @document.font_size 8
            @document.bounding_box([190, 700], :width => 300, :height => 20) do
              @document.text "Guide to the"  , :inline_format => true, :align => :right, :leading => 1
            end
            @document.bounding_box([190, 690], :width => 300, :height => 20) do
              @document.text "<b>" + @title + "</b>" , :inline_format => true, :align => :right, :leading => 1
            end
            @document.font_size 10
          end


      end

    end


    def is_number?(object)
      true if Float(object) rescue false
    end

  end







end